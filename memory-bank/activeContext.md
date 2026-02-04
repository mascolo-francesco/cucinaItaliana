# Active Context

## Focus Corrente
Sincronizzazione DB remoto completata; prossimo focus su backend e frontend.

## Cambiamenti Recenti
- Eseguito schema e seed sul DB remoto con successo
- Allineate colonne mancanti (`ingredienti.unita_misura`, `ingredienti.prezzo_per_unita`, `vini.prezzo_per_bottiglia`, `foto.alt_text`)
- Convertita `ricette_ingredienti.quantita` in `quantita_per_persona` (DECIMAL)
- Corretto `db/seed.sql` (relazioni, ingredienti mancanti, riferimenti errati)

## Prossimi Passi
- Implementare backend Flask con API per:
  - Autenticazione utenti
  - Lista ricette con filtri per genere
  - Calcolo costi automatico
  - Gestione carrello e checkout
- Implementare frontend per visualizzazione e interazione

## Decisioni Attive
- Nomenclatura italiana per tabelle (utenti, ricette, ingredienti, vini, carrelli, ordini)
- Quantità per persona come DECIMAL per calcoli precisi
- Prezzo ingredienti per unità di misura, vini per bottiglia
- Carrello unico per utente (UNIQUE KEY su utente_id)
- Order items con storico prezzi al momento dell'acquisto
