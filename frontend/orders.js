const API_BASE = (() => {
  if (window.location.protocol === "file:") {
    return "http://localhost:5000/api";
  }
  return "/api";
})();

let currentUser = null;

const userStatus = document.getElementById("userStatus");
const logoutBtn = document.getElementById("logoutBtn");
const loginForm = document.getElementById("loginForm");
const loginState = document.getElementById("loginState");
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
  } else {
    userStatus.innerHTML = '<span class="status-dot"></span><span>Non autenticato</span>';
    logoutBtn.hidden = true;
    loginForm.hidden = false;
    loginState.hidden = true;
  }
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
    await loadOrders();
  } catch (error) {
    alert(error.message);
  }
});

logoutBtn.addEventListener("click", async () => {
  await apiFetch("/logout", { method: "POST" });
  currentUser = null;
  updateAuthUI();
  await loadOrders();
});

(async function init() {
  try {
    await loadMe();
    await loadOrders();
  } catch (error) {
    console.error(error);
  }
})();
