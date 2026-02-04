# System Patterns

## Architettura
- Frontend: UI per lista ricette, filtri, carrello, autenticazione.
- Backend: API per ricette, utenti, carrello, acquisti.
- Database relazionale con tabelle per ricette, ingredienti, generi, vini, utenti, carrello/acquisti.

## Pattern Chiave
- Relazioni molti-a-molti: ricette-generi, ricette-ingredienti, ricette-vini.
- Calcolo prezzo: somma (quantita * prezzo unita') per ricetta e per numero persone.
- Autorizzazione: operazioni carrello/checkout solo per utenti autenticati.
