# System Patterns

## Architettura
- **Frontend**: HTML/CSS/JS vanilla per lista ricette, filtri, carrello, autenticazione
- **Backend**: Flask API per ricette, utenti, carrello, checkout
- **Database**: MySQL remoto su Aiven (cucina_italiana) con nomenclatura italiana

## Schema Database
### Tabelle Principali
- `utenti`: username, email, password_hash, nome, cognome
- `ricette`: titolo, descrizione
- `ingredienti`: nome, unita_misura, prezzo_per_unita (DECIMAL)
- `vini`: nome, descrizione, tipo, nazione, regione, prezzo_per_bottiglia (DECIMAL)
- `generi`: nome, descrizione

### Tabelle Relazionali
- `ricette_ingredienti`: quantita_per_persona (DECIMAL)
- `ricette_vini`: annata (YEAR)
- `ricette_generi`: relazione molti-a-molti
- `foto`: url immagini ricette
- `video`: url video ricette
- `valutazioni`: utente-ricetta con punteggio
- `preferiti`: ricette salvate da utenti

### Tabelle Carrello/Ordini
- `carrelli`: un carrello per utente (UNIQUE KEY)
- `cart_items`: ricetta_id, num_persone, vino_id (opzionale)
- `ordini`: utente_id, totale, created_at
- `order_items`: snapshot ordine con prezzi storici

## Pattern Chiave
### Calcolo Prezzi
```
costo_ricetta = SUM(ingrediente.prezzo_per_unita * ricette_ingredienti.quantita_per_persona)
costo_per_persone = costo_ricetta * num_persone
costo_totale_carrello = SUM(costi_ricette) + SUM(vini_opzionali.prezzo_per_bottiglia)
```

### Autorizzazione
- Utenti non autenticati: solo visualizzazione ricette e prezzi
- Utenti autenticati: carrello, checkout, valutazioni, preferiti

### Gestione Carrello
- Un solo carrello attivo per utente
- Ogni item: ricetta + numero persone + vino opzionale
- Calcolo dinamico del totale
- Al checkout: crea ordine, salva prezzi snapshot, svuota carrello
