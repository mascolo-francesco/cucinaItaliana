# La Cucina Italiana – Stato del progetto

Questo progetto implementa la web app richiesta da SPEC.md per consultare ricette e acquistare ingredienti completi per una ricetta. L’applicazione è già funzionante end‑to‑end: include autenticazione, catalogo ricette con filtri, calcolo dei costi, carrello e conferma dell’acquisto con registrazione dell’ordine.

Dal punto di vista dell’esperienza utente, chi è autenticato può aggiungere ricette al carrello, scegliere il numero di persone e (se presente) il vino consigliato, vedere il totale e completare l’acquisto. Chi non è autenticato può comunque vedere l’elenco delle ricette e i relativi costi per persona, ma non può acquistare.

Rispetto a SPEC.md, tutte le funzionalità richieste sono presenti e coerenti. Non ci sono parti mancanti rispetto allo spec e questo va considerato completo.

Come funzionalità aggiuntiva, oltre a quanto richiesto dallo spec, è stata aggiunta una pagina “Ordini” separata (`frontend/orders.html`) che mostra lo storico degli acquisti dell’utente autenticato. La voce “Ordini” in navbar porta a questa pagina. La voce “Preferiti” invece non è implementata, perché non è prevista da SPEC.md.

