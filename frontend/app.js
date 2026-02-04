const API_BASE = (() => {
  if (window.location.protocol === "file:") {
    return "http://localhost:5000/api";
  }
  return "/api";
})();

let currentUser = null;
let recipes = [];
let cart = { items: [], total: 0 };
const wineCache = new Map();

const userStatus = document.getElementById("userStatus");
const logoutBtn = document.getElementById("logoutBtn");
const loginForm = document.getElementById("loginForm");
const loginState = document.getElementById("loginState");
const genreSelect = document.getElementById("genreSelect");
const recipesEl = document.getElementById("recipes");
const cartItemsEl = document.getElementById("cartItems");
const cartTotalEl = document.getElementById("cartTotal");
const cartCountEl = document.getElementById("cartCount");
const checkoutBtn = document.getElementById("checkoutBtn");
const ordersListEl = document.getElementById("ordersList");

const currency = (value) => `€ ${value.toFixed(2).replace(".", ",")}`;

async function apiFetch(path, options = {}) {
  const response = await fetch(`${API_BASE}${path}`, {
    credentials: "include",
    headers: { "Content-Type": "application/json" },
    ...options,
  });
  const data = await response.json();
  if (!response.ok) {
    throw new Error(data.error || "Errore di rete");
  }
  return data;
}

async function loadMe() {
  const data = await apiFetch("/me");
  currentUser = data.user;
  updateAuthUI();
}

function updateAuthUI() {
  if (currentUser) {
    userStatus.innerHTML = `<span class="status-dot"></span><span>Ciao, ${currentUser.full_name}</span>`;
    logoutBtn.hidden = false;
    loginForm.hidden = true;
    loginState.hidden = false;
    checkoutBtn.disabled = cart.items.length === 0;
  } else {
    userStatus.innerHTML = '<span class="status-dot"></span><span>Non autenticato</span>';
    logoutBtn.hidden = true;
    loginForm.hidden = false;
    loginState.hidden = true;
    checkoutBtn.disabled = true;
  }
}

async function loadGenres() {
  const data = await apiFetch("/genres");
  data.genres.forEach((genre) => {
    const option = document.createElement("option");
    option.value = genre.name;
    option.textContent = genre.name;
    genreSelect.appendChild(option);
  });
}

async function loadRecipes() {
  const genre = genreSelect.value;
  const query = genre ? `?genre=${encodeURIComponent(genre)}` : "";
  const data = await apiFetch(`/recipes${query}`);
  recipes = data.recipes;
  renderRecipes();
}

async function loadCart() {
  if (!currentUser) {
    cart = { items: [], total: 0 };
    renderCart();
    return;
  }
  const data = await apiFetch("/cart");
  cart = data;
  renderCart();
}

async function loadOrders() {
  if (!ordersListEl) return;
  if (!currentUser) {
    ordersListEl.innerHTML = `
      <div class="orders-empty">
        <p>Accedi per vedere i tuoi ordini registrati.</p>
      </div>
    `;
    return;
  }
  try {
    const data = await apiFetch("/orders");
    renderOrders(data.orders || []);
  } catch (error) {
    ordersListEl.innerHTML = `
      <div class="orders-empty">
        <p>Non è stato possibile caricare gli ordini.</p>
      </div>
    `;
  }
}

function renderOrders(orders) {
  ordersListEl.innerHTML = "";
  if (!orders.length) {
    ordersListEl.innerHTML = `
      <div class="orders-empty">
        <p>Nessun ordine registrato al momento.</p>
      </div>
    `;
    return;
  }

  orders.forEach((order) => {
    const orderEl = document.createElement("article");
    orderEl.className = "order-card";
    const date = order.created_at ? new Date(order.created_at) : null;
    const dateLabel = date ? date.toLocaleDateString("it-IT") : "Data non disponibile";

    const itemsHtml = (order.items || [])
      .map(
        (item) => `
          <li>
            <span>${item.recipe_title} · ${item.persons} persone</span>
            <span>${currency(item.item_total || 0)}</span>
          </li>
          ${item.wine_name ? `<li class="order-wine">Vino: ${item.wine_name}</li>` : ""}
        `
      )
      .join("");

    orderEl.innerHTML = `
      <div class="order-header">
        <div>
          <strong>Ordine #${order.id}</strong>
          <div class="order-meta">${dateLabel} · ${order.status || "confermato"}</div>
        </div>
        <div class="order-total">${currency(order.total || 0)}</div>
      </div>
      <ul class="order-items">
        ${itemsHtml}
      </ul>
    `;
    ordersListEl.appendChild(orderEl);
  });
}

function renderRecipes() {
  recipesEl.innerHTML = "";
  recipes.forEach((recipe, index) => {
    const card = document.createElement("article");
    card.className = "recipe-card";
    card.style.animationDelay = `${index * 0.05}s`;

    const tags = (recipe.genres || "")
      .split(",")
      .map((tag) => tag.trim())
      .filter(Boolean)
      .map((tag) => `<span class="tag">${tag}</span>`)
      .join("");

    card.innerHTML = `
      <img src="${recipe.image_url}" alt="${recipe.title}" />
      <div class="recipe-meta">
        <h3>${recipe.title}</h3>
        <div class="recipe-tags">${tags}</div>
        <p>${recipe.description}</p>
        <p><strong>${currency(recipe.cost_per_person)}</strong> per persona</p>
        <div class="recipe-actions">
          <input type="number" min="1" value="2" data-persons />
          <select data-wine>
            <option value="">Vino consigliato</option>
          </select>
          <button class="primary" data-add>Aggiungi</button>
        </div>
      </div>
    `;

    const addBtn = card.querySelector("[data-add]");
    const personsInput = card.querySelector("[data-persons]");
    const wineSelect = card.querySelector("[data-wine]");
    const imgEl = card.querySelector("img");

    imgEl.addEventListener("error", () => {
      imgEl.src = "/assets/placeholder.svg";
    });

    if (!currentUser) {
      addBtn.disabled = true;
    }

    wineSelect.addEventListener("focus", () => loadWines(recipe.id, wineSelect));

    addBtn.addEventListener("click", async () => {
      if (!currentUser) return;
      const persons = parseInt(personsInput.value, 10) || 1;
      const wineId = wineSelect.value ? parseInt(wineSelect.value, 10) : null;
      
      // Feedback visivo
      addBtn.textContent = "Aggiunto!";
      addBtn.disabled = true;
      
      await apiFetch("/cart/items", {
        method: "POST",
        body: JSON.stringify({ recipe_id: recipe.id, persons, wine_id: wineId }),
      });
      
      await loadCart();
      
      // Ripristina pulsante
      setTimeout(() => {
        addBtn.textContent = "Aggiungi";
        addBtn.disabled = false;
      }, 1000);
    });

    recipesEl.appendChild(card);
  });
}

async function loadWines(recipeId, selectEl) {
  if (wineCache.has(recipeId)) {
    fillWineSelect(selectEl, wineCache.get(recipeId));
    return;
  }
  const data = await apiFetch(`/recipes/${recipeId}/wines`);
  wineCache.set(recipeId, data.wines);
  fillWineSelect(selectEl, data.wines);
}

function fillWineSelect(selectEl, wines) {
  if (selectEl.dataset.loaded) return;
  wines.forEach((wine) => {
    const option = document.createElement("option");
    option.value = wine.id;
    option.textContent = `${wine.name} ${wine.vintage} (${currency(wine.price_per_bottle)})`;
    selectEl.appendChild(option);
  });
  selectEl.dataset.loaded = "true";
}

function renderCart() {
  cartItemsEl.innerHTML = "";
  
  // Aggiorna contatore carrello
  if (cartCountEl) {
    cartCountEl.textContent = cart.items.length;
  }
  
  if (cart.items.length === 0) {
    cartItemsEl.innerHTML = `
      <div class="cart-empty">
        <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
          <path d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z"/>
        </svg>
        <p>Carrello vuoto</p>
      </div>
    `;
  }

  cart.items.forEach((item) => {
    const div = document.createElement("div");
    div.className = "cart-item";
    div.innerHTML = `
      <strong>${item.title}</strong>
      <div>${item.persons} persone · ${currency(item.unit_cost)} / persona</div>
      ${item.wine_name ? `<div>Vino: ${item.wine_name}</div>` : ""}
      <div><strong>Totale: ${currency(item.item_total)}</strong></div>
      <button class="btn-ghost" data-remove="${item.id}">Rimuovi</button>
    `;
    div.querySelector("button").addEventListener("click", async () => {
      await apiFetch(`/cart/items/${item.id}`, { method: "DELETE" });
      await loadCart();
    });
    cartItemsEl.appendChild(div);
  });

  cartTotalEl.textContent = currency(cart.total || 0);
  checkoutBtn.disabled = !currentUser || cart.items.length === 0;
}

loginForm.addEventListener("submit", async (event) => {
  event.preventDefault();
  const formData = new FormData(loginForm);
  try {
    await apiFetch("/login", {
      method: "POST",
      body: JSON.stringify({
        email: formData.get("email"),
        password: formData.get("password"),
      }),
    });
    await loadMe();
    await loadCart();
    await loadOrders();
    renderRecipes();
  } catch (error) {
    alert(error.message);
  }
});

logoutBtn.addEventListener("click", async () => {
  await apiFetch("/logout", { method: "POST" });
  currentUser = null;
  updateAuthUI();
  await loadCart();
  await loadOrders();
  renderRecipes();
});

genreSelect.addEventListener("change", loadRecipes);

checkoutBtn.addEventListener("click", async () => {
  try {
    await apiFetch("/checkout", { method: "POST" });
    await loadCart();
    await loadOrders();
    alert("Acquisto confermato! Ordine registrato.");
  } catch (error) {
    alert(error.message);
  }
});

(async function init() {
  try {
    await loadMe();
    await loadGenres();
    await loadRecipes();
    await loadCart();
    await loadOrders();
  } catch (error) {
    console.error(error);
  }
})();
