-- Schema: La Cucina Italiana
-- Database adattato alla struttura esistente con nomi italiani
CREATE DATABASE IF NOT EXISTS cucina_italiana
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE cucina_italiana;

-- Tabella utenti con campi aggiuntivi per nome e cognome
CREATE TABLE IF NOT EXISTS utenti (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) NOT NULL UNIQUE,
  email VARCHAR(100) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  nome VARCHAR(100),
  cognome VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_login TIMESTAMP NULL
) ENGINE=InnoDB;

-- Tabella ricette
CREATE TABLE IF NOT EXISTS ricette (
  id INT AUTO_INCREMENT PRIMARY KEY,
  titolo VARCHAR(255) NOT NULL,
  descrizione TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_titolo (titolo)
) ENGINE=InnoDB;

-- Tabella foto ricette
CREATE TABLE IF NOT EXISTS foto (
  id INT AUTO_INCREMENT PRIMARY KEY,
  ricetta_id INT NOT NULL,
  url VARCHAR(255) NOT NULL,
  alt_text VARCHAR(150),
  FOREIGN KEY (ricetta_id) REFERENCES ricette(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Tabella video ricette
CREATE TABLE IF NOT EXISTS video (
  id INT AUTO_INCREMENT PRIMARY KEY,
  ricetta_id INT NOT NULL,
  url VARCHAR(255) NOT NULL,
  titolo VARCHAR(150),
  FOREIGN KEY (ricetta_id) REFERENCES ricette(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Tabella generi culinari
CREATE TABLE IF NOT EXISTS generi (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(100) NOT NULL UNIQUE,
  descrizione TEXT
) ENGINE=InnoDB;

-- Relazione molti-a-molti ricette-generi
CREATE TABLE IF NOT EXISTS ricette_generi (
  ricetta_id INT NOT NULL,
  genere_id INT NOT NULL,
  PRIMARY KEY (ricetta_id, genere_id),
  FOREIGN KEY (ricetta_id) REFERENCES ricette(id) ON DELETE CASCADE,
  FOREIGN KEY (genere_id) REFERENCES generi(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Tabella ingredienti con prezzo e unità di misura
CREATE TABLE IF NOT EXISTS ingredienti (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(100) NOT NULL UNIQUE,
  unita_misura VARCHAR(20) NOT NULL DEFAULT 'g',
  prezzo_per_unita DECIMAL(10,2) NOT NULL DEFAULT 0.00
) ENGINE=InnoDB;

-- Relazione molti-a-molti ricette-ingredienti con quantità per persona
CREATE TABLE IF NOT EXISTS ricette_ingredienti (
  ricetta_id INT NOT NULL,
  ingrediente_id INT NOT NULL,
  quantita_per_persona DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (ricetta_id, ingrediente_id),
  FOREIGN KEY (ricetta_id) REFERENCES ricette(id) ON DELETE CASCADE,
  FOREIGN KEY (ingrediente_id) REFERENCES ingredienti(id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Tabella vini con prezzo per bottiglia
CREATE TABLE IF NOT EXISTS vini (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(100) NOT NULL,
  descrizione TEXT,
  tipo VARCHAR(50),
  nazione VARCHAR(100),
  regione VARCHAR(100),
  prezzo_per_bottiglia DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  INDEX idx_tipo (tipo),
  INDEX idx_regione (regione)
) ENGINE=InnoDB;

-- Relazione molti-a-molti ricette-vini con annata
CREATE TABLE IF NOT EXISTS ricette_vini (
  ricetta_id INT NOT NULL,
  vino_id INT NOT NULL,
  annata YEAR NOT NULL,
  PRIMARY KEY (ricetta_id, vino_id, annata),
  FOREIGN KEY (ricetta_id) REFERENCES ricette(id) ON DELETE CASCADE,
  FOREIGN KEY (vino_id) REFERENCES vini(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Tabella valutazioni (un utente può valutare una ricetta una sola volta)
CREATE TABLE IF NOT EXISTS valutazioni (
  utente_id INT NOT NULL,
  ricetta_id INT NOT NULL,
  punteggio TINYINT NOT NULL CHECK (punteggio BETWEEN 1 AND 5),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (utente_id, ricetta_id),
  FOREIGN KEY (utente_id) REFERENCES utenti(id) ON DELETE CASCADE,
  FOREIGN KEY (ricetta_id) REFERENCES ricette(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Tabella preferiti (ricette salvate dagli utenti)
CREATE TABLE IF NOT EXISTS preferiti (
  utente_id INT NOT NULL,
  ricetta_id INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (utente_id, ricetta_id),
  FOREIGN KEY (utente_id) REFERENCES utenti(id) ON DELETE CASCADE,
  FOREIGN KEY (ricetta_id) REFERENCES ricette(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Tabella carrelli (un utente ha un carrello attivo)
CREATE TABLE IF NOT EXISTS carrelli (
  id INT AUTO_INCREMENT PRIMARY KEY,
  utente_id INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY unique_user_cart (utente_id),
  FOREIGN KEY (utente_id) REFERENCES utenti(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Tabella elementi del carrello
CREATE TABLE IF NOT EXISTS cart_items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  carrello_id INT NOT NULL,
  ricetta_id INT NOT NULL,
  num_persone INT NOT NULL DEFAULT 1 CHECK (num_persone > 0),
  vino_id INT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (carrello_id) REFERENCES carrelli(id) ON DELETE CASCADE,
  FOREIGN KEY (ricetta_id) REFERENCES ricette(id) ON DELETE RESTRICT,
  FOREIGN KEY (vino_id) REFERENCES vini(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- Tabella ordini completati
CREATE TABLE IF NOT EXISTS ordini (
  id INT AUTO_INCREMENT PRIMARY KEY,
  utente_id INT NOT NULL,
  totale DECIMAL(10,2) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  stato VARCHAR(50) DEFAULT 'confermato',
  FOREIGN KEY (utente_id) REFERENCES utenti(id) ON DELETE RESTRICT,
  INDEX idx_utente_data (utente_id, created_at)
) ENGINE=InnoDB;

-- Tabella dettagli ordini
CREATE TABLE IF NOT EXISTS order_items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  ordine_id INT NOT NULL,
  ricetta_id INT NOT NULL,
  num_persone INT NOT NULL,
  costo_unitario DECIMAL(10,2) NOT NULL,
  costo_totale DECIMAL(10,2) NOT NULL,
  vino_id INT NULL,
  prezzo_vino DECIMAL(10,2) NULL,
  FOREIGN KEY (ordine_id) REFERENCES ordini(id) ON DELETE CASCADE,
  FOREIGN KEY (ricetta_id) REFERENCES ricette(id) ON DELETE RESTRICT,
  FOREIGN KEY (vino_id) REFERENCES vini(id) ON DELETE SET NULL
) ENGINE=InnoDB;
