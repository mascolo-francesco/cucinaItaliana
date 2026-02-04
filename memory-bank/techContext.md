# Tech Context

## Tecnologie Utilizzate
### Database
- **MySQL 8.0** su Aiven Cloud
- Host: mysql-chatdb-chatwithdb.h.aivencloud.com:19515
- Database: `cucina_italiana`
- SSL obbligatorio
- Charset: utf8mb4, Collation: utf8mb4_unicode_ci

### Backend
- **Python 3.x** con Flask
- `mysql-connector-python` o `PyMySQL` per connessione DB
- `flask-session` per gestione sessioni utente
- Hashing password con SHA2 (o bcrypt per produzione)

### Frontend
- HTML5 semantico
- CSS3 vanilla (no framework)
- JavaScript vanilla per interattività
- Fetch API per chiamate backend

## Setup Sviluppo
- Repo locale in `/Users/francescomascolo/Desktop/cucinaitaliana`
- File configurazione: `.env.example` con credenziali DB
- Backend: `backend/config.py`, `backend/db.py`, `backend/app.py`
- Frontend: `frontend/index.html`, `styles.css`, `app.js`
- Schema DB: `db/schema.sql`, `db/seed.sql`

## Vincoli
- Nessun framework obbligatorio (CSS/JS)
- Codice spiegabile e semplice per esame
- Calcoli prezzi sul backend (non client-side)
- Architettura frontend/backend separata

## Dipendenze
### Backend (requirements.txt)
```
Flask==3.0.0
mysql-connector-python==8.2.0
python-dotenv==1.0.0
Flask-CORS==4.0.0
```

### Database Client
- MySQL CLI per test: `mysql -h HOST -P PORT -u USER -pPASSWORD cucina_italiana --ssl-mode=REQUIRED`
