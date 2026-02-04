Verifica — Realizzazione di una Web App
La Cucina Italiana – Acquisto di ricette complete

Contesto
Il sito web “La Cucina Italiana” dispone già di una base di dati progettata nella precedente verifica.
Scopo di questa verifica è invece la realizzazione di una web application che consenta agli utenti di
consultare le ricette e di acquistare una o più ricette complete, intese come l’insieme di tutti gli
ingredienti necessari alla loro preparazione nelle corrette quantità.
L’utente non acquista quindi singoli ingredienti separatamente, ma seleziona una ricetta e indica per
quante persone desidera prepararla; il sistema calcola automaticamente il costo complessivo della
ricetta in base ai prezzi degli ingredienti e, una volta effettuato l’acquisto, un corriere porta a casa
dell’utente gli ingredienti per preparare la ricetta.
Creazione del database
Prendere in considerazione il testo della verifica precedente e creare il database. Aggiungere anche
le informazioni necessarie allo svolgimento di questa verifica.
Popolamento del database
Popolare il database con dati realistici, includendo almeno:
a. 5 ricette complete di descrizione, genere, ingredienti, quantità,vini consigliati e immagini
(prendere le ricette dal sito https://www.lacucinaitaliana.it );
b. 3 utenti registrati con credenziali di accesso;
c. gli ingredienti (con unità di misura e prezzo relativo all’unità di misurta)
d. i vini per le ricette
Realizzazione della Web App
La web application deve implementare le seguenti funzionalità:
a. Login
- autenticazione dell’utente tramite credenziali;
- visualizzazione del nome dell’utente autenticato durante la navigazione.
b. Visualizzazione delle ricette
- visualizzazione di tutte le ricette presenti nel database;
- possibilità di filtrare le ricette per genere (primi, secondi, vegetariani, celiaci, ecc.);
- per ogni ricetta devono essere mostrati nome, immagine e costo per una persona.

c. Carrello
- selezione di una o più ricette e del vino a loro abbinato (facoltativo);
- indicazione del numero di persone per ciascuna ricetta;
- calcolo automatico del costo della ricetta;
- inserimento delle ricette selezionate nel carrello;
- visualizzazione del totale complessivo.
d. Checkout
- conferma dell’acquisto delle ricette presenti nel carrello;
- registrazione dell’acquisto nel sistema;
- svuotamento del carrello.
e. Logout
- possibilità di effettuare il logout e tornare allo stato di utente non autenticato.
Se l’utente non è autenticato:
- può visualizzare solo l’elenco delle ricette;
- per ciascuna ricetta deve essere visibile il costo per persona;
- non può aggiungere ricette al carrello né effettuare acquisti.
Note finali
L’interfaccia può essere semplice ma deve risultare chiara e funzionale.
La logica di calcolo dei costi deve essere corretta e coerente con i dati presenti nel database.
L’architettura deve presentare un frontend e un backend: non sono richiesti framework/librerie
particolari ma lo studente deve essere in grado di spiegare il codice prodotto