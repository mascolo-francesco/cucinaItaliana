from decimal import Decimal
from pathlib import Path
from flask import Flask, jsonify, request, session, send_from_directory
from flask_cors import CORS
from config import SECRET_KEY
from db import get_connection

FRONTEND_DIR = Path(__file__).resolve().parent.parent / "frontend"
app = Flask(__name__, static_folder=str(FRONTEND_DIR), static_url_path="")
app.secret_key = SECRET_KEY
CORS(app, supports_credentials=True)


def _decimal_to_float(value):
    if isinstance(value, Decimal):
        return float(value)
    return value


def _row_to_dict(cursor, row):
    return {col[0]: _decimal_to_float(val) for col, val in zip(cursor.description, row)}


def current_user_id():
    return session.get("user_id")


def require_auth():
    if not current_user_id():
        return jsonify({"error": "Utente non autenticato."}), 401
    return None


@app.get("/api/health")
def health():
    return jsonify({"status": "ok"})


@app.get("/")
def serve_index():
    return send_from_directory(app.static_folder, "index.html")


@app.get("/<path:filename>")
def serve_static(filename):
    return send_from_directory(app.static_folder, filename)


@app.post("/api/login")
def login():
    data = request.get_json(silent=True) or {}
    email = data.get("email", "").strip()
    password = data.get("password", "")

    if not email or not password:
        return jsonify({"error": "Email e password sono obbligatorie."}), 400

    conn = get_connection()
    try:
        cursor = conn.cursor(buffered=True)
        cursor.execute(
            """
            SELECT id, CONCAT(nome, ' ', cognome) AS full_name, email
            FROM utenti
            WHERE email = %s AND password_hash = SHA2(%s, 256)
            """,
            (email, password),
        )
        row = cursor.fetchone()
        if not row:
            return jsonify({"error": "Credenziali non valide."}), 401
        user = _row_to_dict(cursor, row)
        session["user_id"] = user["id"]
        session["user_name"] = user["full_name"]
        return jsonify({"user": user})
    finally:
        conn.close()


@app.post("/api/logout")
def logout():
    session.clear()
    return jsonify({"status": "logged_out"})


@app.get("/api/me")
def me():
    if not current_user_id():
        return jsonify({"user": None})
    return jsonify({"user": {"id": session["user_id"], "full_name": session["user_name"]}})


@app.get("/api/genres")
def list_genres():
    conn = get_connection()
    try:
        cursor = conn.cursor(buffered=True)
        cursor.execute("SELECT id, nome AS name FROM generi ORDER BY nome")
        genres = [_row_to_dict(cursor, row) for row in cursor.fetchall()]
        return jsonify({"genres": genres})
    finally:
        conn.close()


@app.get("/api/recipes")
def list_recipes():
    genre = request.args.get("genre")
    conn = get_connection()
    try:
        cursor = conn.cursor(buffered=True)
        if genre:
            cursor.execute(
                """
                SELECT r.id,
                       r.titolo AS title,
                       r.descrizione AS description,
                       f.url AS image_url,
                       c.cost_per_person,
                       GROUP_CONCAT(DISTINCT g.nome ORDER BY g.nome SEPARATOR ', ') AS genres
                FROM ricette r
                JOIN (
                    SELECT ri.ricetta_id,
                           ROUND(SUM(ri.quantita_per_persona * i.prezzo_per_unita), 2) AS cost_per_person
                    FROM ricette_ingredienti ri
                    JOIN ingredienti i ON i.id = ri.ingrediente_id
                    GROUP BY ri.ricetta_id
                ) c ON c.ricetta_id = r.id
                JOIN ricette_generi rg ON r.id = rg.ricetta_id
                JOIN generi g ON g.id = rg.genere_id
                LEFT JOIN (
                    SELECT ricetta_id, MIN(id) AS min_id
                    FROM foto
                    GROUP BY ricetta_id
                ) fm ON fm.ricetta_id = r.id
                LEFT JOIN foto f ON f.id = fm.min_id
                WHERE g.nome = %s
                GROUP BY r.id, f.url, c.cost_per_person
                ORDER BY r.titolo
                """,
                (genre,),
            )
        else:
            cursor.execute(
                """
                SELECT r.id,
                       r.titolo AS title,
                       r.descrizione AS description,
                       f.url AS image_url,
                       c.cost_per_person,
                       GROUP_CONCAT(DISTINCT g.nome ORDER BY g.nome SEPARATOR ', ') AS genres
                FROM ricette r
                JOIN (
                    SELECT ri.ricetta_id,
                           ROUND(SUM(ri.quantita_per_persona * i.prezzo_per_unita), 2) AS cost_per_person
                    FROM ricette_ingredienti ri
                    JOIN ingredienti i ON i.id = ri.ingrediente_id
                    GROUP BY ri.ricetta_id
                ) c ON c.ricetta_id = r.id
                LEFT JOIN ricette_generi rg ON r.id = rg.ricetta_id
                LEFT JOIN generi g ON g.id = rg.genere_id
                LEFT JOIN (
                    SELECT ricetta_id, MIN(id) AS min_id
                    FROM foto
                    GROUP BY ricetta_id
                ) fm ON fm.ricetta_id = r.id
                LEFT JOIN foto f ON f.id = fm.min_id
                GROUP BY r.id, f.url, c.cost_per_person
                ORDER BY r.titolo
                """
            )
        recipes = [_row_to_dict(cursor, row) for row in cursor.fetchall()]
        return jsonify({"recipes": recipes})
    finally:
        conn.close()


@app.get("/api/recipes/<int:recipe_id>/wines")
def list_recipe_wines(recipe_id):
    conn = get_connection()
    try:
        cursor = conn.cursor(buffered=True)
        cursor.execute(
            """
            SELECT w.id,
                   w.nome AS name,
                   w.tipo AS wine_type,
                   w.regione AS region,
                   w.prezzo_per_bottiglia AS price_per_bottle,
                   rv.annata AS vintage
            FROM ricette_vini rv
            JOIN vini w ON w.id = rv.vino_id
            WHERE rv.ricetta_id = %s
            ORDER BY w.nome
            """,
            (recipe_id,),
        )
        wines = [_row_to_dict(cursor, row) for row in cursor.fetchall()]
        return jsonify({"wines": wines})
    finally:
        conn.close()


def get_or_create_cart(cursor, user_id):
    cursor.execute(
        "SELECT id FROM carrelli WHERE utente_id = %s ORDER BY created_at DESC LIMIT 1",
        (user_id,),
    )
    row = cursor.fetchone()
    if row:
        return row[0]
    cursor.execute("INSERT INTO carrelli (utente_id) VALUES (%s)", (user_id,))
    return cursor.lastrowid


def compute_unit_cost(cursor, recipe_id):
    cursor.execute(
        """
        SELECT ROUND(SUM(ri.quantita_per_persona * i.prezzo_per_unita), 2)
        FROM ricette_ingredienti ri
        JOIN ingredienti i ON i.id = ri.ingrediente_id
        WHERE ri.ricetta_id = %s
        """,
        (recipe_id,),
    )
    row = cursor.fetchone()
    return row[0] if row and row[0] is not None else Decimal("0.00")


def fetch_cart(cursor, cart_id):
    cursor.execute(
        """
        SELECT ci.id,
               ci.num_persone AS persons,
               r.id AS recipe_id,
               r.titolo AS title,
               (SELECT ROUND(SUM(ri.quantita_per_persona * i.prezzo_per_unita), 2)
                FROM ricette_ingredienti ri
                JOIN ingredienti i ON i.id = ri.ingrediente_id
                WHERE ri.ricetta_id = r.id) AS unit_cost,
               w.id AS wine_id,
               w.nome AS wine_name,
               w.prezzo_per_bottiglia AS price_per_bottle
        FROM cart_items ci
        JOIN ricette r ON r.id = ci.ricetta_id
        LEFT JOIN vini w ON w.id = ci.vino_id
        WHERE ci.carrello_id = %s
        ORDER BY ci.id DESC
        """,
        (cart_id,),
    )
    items = []
    total = Decimal("0.00")
    for row in cursor.fetchall():
        item = _row_to_dict(cursor, row)
        unit_cost = Decimal(str(item["unit_cost"] or 0))
        wine_price = Decimal(str(item["price_per_bottle"] or 0))
        item_total = unit_cost * Decimal(item["persons"]) + wine_price
        total += item_total
        item["item_total"] = float(item_total)
        items.append(item)
    return items, float(total)


@app.get("/api/cart")
def get_cart():
    auth_error = require_auth()
    if auth_error:
        return auth_error

    conn = get_connection()
    try:
        cursor = conn.cursor(buffered=True)
        cart_id = get_or_create_cart(cursor, current_user_id())
        items, total = fetch_cart(cursor, cart_id)
        return jsonify({"items": items, "total": total})
    finally:
        conn.close()


@app.post("/api/cart/items")
def add_cart_item():
    auth_error = require_auth()
    if auth_error:
        return auth_error

    data = request.get_json(silent=True) or {}
    recipe_id = data.get("recipe_id")
    persons = int(data.get("persons", 1))
    wine_id = data.get("wine_id")

    if not recipe_id or persons < 1:
        return jsonify({"error": "Ricetta e numero persone sono obbligatori."}), 400

    conn = get_connection()
    try:
        cursor = conn.cursor(buffered=True)
        cursor.execute("SELECT id FROM ricette WHERE id = %s", (recipe_id,))
        if not cursor.fetchone():
            return jsonify({"error": "Ricetta non trovata."}), 404

        if wine_id:
            cursor.execute(
                "SELECT 1 FROM ricette_vini WHERE ricetta_id = %s AND vino_id = %s",
                (recipe_id, wine_id),
            )
            if not cursor.fetchone():
                return jsonify({"error": "Vino non valido per la ricetta."}), 400

        cart_id = get_or_create_cart(cursor, current_user_id())
        cursor.execute(
            """
            INSERT INTO cart_items (carrello_id, ricetta_id, num_persone, vino_id)
            VALUES (%s, %s, %s, %s)
            """,
            (cart_id, recipe_id, persons, wine_id),
        )
        conn.commit()

        items, total = fetch_cart(cursor, cart_id)
        return jsonify({"items": items, "total": total})
    finally:
        conn.close()


@app.delete("/api/cart/items/<int:item_id>")
def delete_cart_item(item_id):
    auth_error = require_auth()
    if auth_error:
        return auth_error

    conn = get_connection()
    try:
        cursor = conn.cursor(buffered=True)
        cursor.execute(
            "SELECT id FROM carrelli WHERE utente_id = %s ORDER BY created_at DESC LIMIT 1",
            (current_user_id(),),
        )
        row = cursor.fetchone()
        if not row:
            return jsonify({"items": [], "total": 0})

        cart_id = row[0]
        cursor.execute("DELETE FROM cart_items WHERE id = %s AND carrello_id = %s", (item_id, cart_id))
        conn.commit()

        items, total = fetch_cart(cursor, cart_id)
        return jsonify({"items": items, "total": total})
    finally:
        conn.close()


@app.post("/api/checkout")
def checkout():
    auth_error = require_auth()
    if auth_error:
        return auth_error

    conn = get_connection()
    try:
        cursor = conn.cursor(buffered=True)
        cursor.execute(
            "SELECT id FROM carrelli WHERE utente_id = %s ORDER BY created_at DESC LIMIT 1",
            (current_user_id(),),
        )
        row = cursor.fetchone()
        if not row:
            return jsonify({"error": "Carrello vuoto."}), 400
        cart_id = row[0]

        items, total = fetch_cart(cursor, cart_id)
        if not items:
            return jsonify({"error": "Carrello vuoto."}), 400

        cursor.execute(
            "INSERT INTO ordini (utente_id, totale) VALUES (%s, %s)",
            (current_user_id(), total),
        )
        order_id = cursor.lastrowid

        for item in items:
            cursor.execute(
                """
                INSERT INTO order_items (
                    ordine_id, ricetta_id, num_persone, costo_unitario, costo_totale, vino_id, prezzo_vino
                ) VALUES (%s, %s, %s, %s, %s, %s, %s)
                """,
                (
                    order_id,
                    item["recipe_id"],
                    item["persons"],
                    item["unit_cost"],
                    item["item_total"],
                    item.get("wine_id"),
                    item.get("price_per_bottle"),
                ),
            )

        cursor.execute("DELETE FROM cart_items WHERE carrello_id = %s", (cart_id,))
        conn.commit()

        return jsonify({"status": "ok", "order_id": order_id})
    finally:
        conn.close()


@app.get("/api/orders")
def list_orders():
    auth_error = require_auth()
    if auth_error:
        return auth_error

    conn = get_connection()
    try:
        cursor = conn.cursor(buffered=True)
        cursor.execute(
            """
            SELECT o.id AS order_id,
                   o.totale AS order_total,
                   o.created_at AS order_date,
                   o.stato AS order_status,
                   oi.id AS item_id,
                   oi.num_persone AS persons,
                   oi.costo_unitario AS unit_cost,
                   oi.costo_totale AS item_total,
                   r.titolo AS recipe_title,
                   w.nome AS wine_name
            FROM ordini o
            LEFT JOIN order_items oi ON oi.ordine_id = o.id
            LEFT JOIN ricette r ON r.id = oi.ricetta_id
            LEFT JOIN vini w ON w.id = oi.vino_id
            WHERE o.utente_id = %s
            ORDER BY o.created_at DESC, oi.id ASC
            """,
            (current_user_id(),),
        )

        orders = []
        order_map = {}
        for row in cursor.fetchall():
            data = _row_to_dict(cursor, row)
            order_id = data["order_id"]
            if order_id not in order_map:
                order_entry = {
                    "id": order_id,
                    "total": data["order_total"],
                    "created_at": data["order_date"],
                    "status": data["order_status"],
                    "items": [],
                }
                orders.append(order_entry)
                order_map[order_id] = order_entry

            if data["item_id"] is not None:
                order_map[order_id]["items"].append(
                    {
                        "id": data["item_id"],
                        "recipe_title": data["recipe_title"],
                        "persons": data["persons"],
                        "unit_cost": data["unit_cost"],
                        "item_total": data["item_total"],
                        "wine_name": data["wine_name"],
                    }
                )

        return jsonify({"orders": orders})
    finally:
        conn.close()


if __name__ == "__main__":
    app.run(debug=True)
