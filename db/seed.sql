USE cucina_italiana;

-- Popolamento utenti (minimo 3 come da SPEC)
INSERT INTO utenti (username, email, password_hash, nome, cognome) VALUES
('giulia.bianchi', 'giulia.bianchi@example.com', SHA2('Password123!', 256), 'Giulia', 'Bianchi'),
('luca.rossi', 'luca.rossi@example.com', SHA2('Password123!', 256), 'Luca', 'Rossi'),
('sara.conti', 'sara.conti@example.com', SHA2('Password123!', 256), 'Sara', 'Conti')
ON DUPLICATE KEY UPDATE
  password_hash = VALUES(password_hash),
  nome = VALUES(nome),
  cognome = VALUES(cognome);

-- Generi culinari
INSERT INTO generi (nome, descrizione) VALUES
('Primi piatti', 'Paste, risotti e primi in generale'),
('Secondi piatti', 'Piatti principali di carne o pesce'),
('Carne', 'Piatti a base di carne'),
('Pesce', 'Piatti a base di pesce'),
('Vegetariano', 'Piatti senza carne e pesce')
ON DUPLICATE KEY UPDATE
  descrizione = VALUES(descrizione);

-- Ingredienti con prezzi realistici
INSERT INTO ingredienti (nome, unita_misura, prezzo_per_unita) VALUES
('Spaghetti', 'g', 0.008),
('Guanciale', 'g', 0.06),
('Uova', 'pz', 0.50),
('Pecorino Romano', 'g', 0.08),
('Pepe nero', 'g', 0.10),
('Riso Carnaroli', 'g', 0.008),
('Brodo vegetale', 'ml', 0.003),
('Burro', 'g', 0.02),
('Zafferano', 'g', 5.00),
('Parmigiano Reggiano', 'g', 0.08),
('Sfoglia all'uovo', 'g', 0.015),
('Carne macinata', 'g', 0.03),
('Pancetta', 'g', 0.03),
('Passata di pomodoro', 'g', 0.005),
('Latte', 'ml', 0.002),
('Fettine di vitello', 'g', 0.045),
('Prosciutto crudo', 'g', 0.04),
('Salvia', 'g', 0.10),
('Vino bianco', 'ml', 0.03),
('Sale', 'g', 0.002),
('Branzino', 'g', 0.05),
('Patate', 'g', 0.003),
('Limone', 'g', 0.02),
('Prezzemolo', 'g', 0.05),
('Aglio', 'g', 0.03),
('Olio extravergine d'oliva', 'ml', 0.03),
('Mozzarella', 'g', 0.02),
('Basilico', 'g', 0.08),
('Carota', 'g', 0.004),
('Sedano', 'g', 0.004),
('Cipolla', 'g', 0.004),
('Noce moscata', 'g', 0.20)
ON DUPLICATE KEY UPDATE
  unita_misura = VALUES(unita_misura),
  prezzo_per_unita = VALUES(prezzo_per_unita);

-- Ricette (5 reali)
INSERT INTO ricette (titolo, descrizione) VALUES
('Spaghetti alla Carbonara',
 'La carbonara è un grande classico della cucina romana. Spaghetti, guanciale croccante, pecorino romano, uova e pepe nero. Il segreto sta nella mantecatura perfetta per ottenere una crema vellutata senza panna.'),
('Risotto alla Milanese',
 'Il risotto alla milanese è il simbolo della cucina lombarda. Riso Carnaroli tostato, brodo caldo e zafferano per il classico colore dorato, mantecato con burro e parmigiano.'),
('Lasagne alla Bolognese',
 'Strati di sfoglia all\'uovo, ragù di carne, besciamella e parmigiano. Un grande classico dell\'Emilia-Romagna, ricco e completo.'),
('Saltimbocca alla Romana',
 'Fettine di vitello con prosciutto crudo e salvia, cotte velocemente in padella con burro e vino bianco.'),
('Branzino al Forno',
 'Branzino intero al forno con patate, olio extravergine, aglio e prezzemolo. Un secondo di pesce leggero e profumato.')
ON DUPLICATE KEY UPDATE
  descrizione = VALUES(descrizione);

-- Foto ufficiali
INSERT INTO foto (ricetta_id, url, alt_text)
SELECT r.id, f.url, r.titolo
FROM ricette r
JOIN (
  SELECT 'Spaghetti alla Carbonara' AS titolo, 'https://media-assets.lacucinaitaliana.it/photos/624aad27469de1ccc6e1c2f1/1:1/w_800,c_limit/carbonara.jpg' AS url
  UNION ALL SELECT 'Risotto alla Milanese', 'https://media-assets.lacucinaitaliana.it/photos/61faf0ccf9bff304ce3ebd2e/1:1/w_800,c_limit/risotto-milanese.jpg'
  UNION ALL SELECT 'Lasagne alla Bolognese', 'https://media-assets.lacucinaitaliana.it/photos/61fabcb17cc40c77222bf9e5/1:1/w_800,c_limit/lasagne.jpg'
  UNION ALL SELECT 'Saltimbocca alla Romana', 'https://media-assets.lacucinaitaliana.it/photos/61fd3a291bb4d80ddd55621e/1:1/w_800,c_limit/Saltimbocca-alla-romana6.jpg'
  UNION ALL SELECT 'Branzino al Forno', 'https://media-assets.lacucinaitaliana.it/photos/61fa9bb3c67907ca2e900b31/1:1/w_800,c_limit/branzino.jpg'
) f ON f.titolo = r.titolo
ON DUPLICATE KEY UPDATE
  url = VALUES(url),
  alt_text = VALUES(alt_text);

-- Associazioni ricette-generi
INSERT INTO ricette_generi (ricetta_id, genere_id)
SELECT r.id, g.id
FROM ricette r
JOIN generi g ON (
  (r.titolo = 'Spaghetti alla Carbonara' AND g.nome IN ('Primi piatti','Carne')) OR
  (r.titolo = 'Risotto alla Milanese' AND g.nome IN ('Primi piatti','Vegetariano')) OR
  (r.titolo = 'Lasagne alla Bolognese' AND g.nome IN ('Primi piatti','Carne')) OR
  (r.titolo = 'Saltimbocca alla Romana' AND g.nome IN ('Secondi piatti','Carne')) OR
  (r.titolo = 'Branzino al Forno' AND g.nome IN ('Secondi piatti','Pesce'))
)
ON DUPLICATE KEY UPDATE
  ricetta_id = VALUES(ricetta_id),
  genere_id = VALUES(genere_id);

-- Ingredienti per ricetta (quantità per persona)
INSERT INTO ricette_ingredienti (ricetta_id, ingrediente_id, quantita_per_persona)
SELECT r.id, i.id, q.qty
FROM ricette r
JOIN (
  SELECT 'Spaghetti alla Carbonara' AS titolo, 'Spaghetti' AS ingr, 100 AS qty
  UNION ALL SELECT 'Spaghetti alla Carbonara','Guanciale',40
  UNION ALL SELECT 'Spaghetti alla Carbonara','Uova',1
  UNION ALL SELECT 'Spaghetti alla Carbonara','Pecorino Romano',15
  UNION ALL SELECT 'Spaghetti alla Carbonara','Pepe nero',1

  UNION ALL SELECT 'Risotto alla Milanese','Riso Carnaroli',80
  UNION ALL SELECT 'Risotto alla Milanese','Brodo vegetale',250
  UNION ALL SELECT 'Risotto alla Milanese','Burro',10
  UNION ALL SELECT 'Risotto alla Milanese','Zafferano',0.10
  UNION ALL SELECT 'Risotto alla Milanese','Parmigiano Reggiano',15
  UNION ALL SELECT 'Risotto alla Milanese','Vino bianco',40

  UNION ALL SELECT 'Lasagne alla Bolognese','Sfoglia all\'uovo',90
  UNION ALL SELECT 'Lasagne alla Bolognese','Carne macinata',80
  UNION ALL SELECT 'Lasagne alla Bolognese','Pancetta',25
  UNION ALL SELECT 'Lasagne alla Bolognese','Passata di pomodoro',120
  UNION ALL SELECT 'Lasagne alla Bolognese','Latte',150
  UNION ALL SELECT 'Lasagne alla Bolognese','Burro',15
  UNION ALL SELECT 'Lasagne alla Bolognese','Parmigiano Reggiano',20
  UNION ALL SELECT 'Lasagne alla Bolognese','Carota',10
  UNION ALL SELECT 'Lasagne alla Bolognese','Sedano',10
  UNION ALL SELECT 'Lasagne alla Bolognese','Cipolla',10
  UNION ALL SELECT 'Lasagne alla Bolognese','Noce moscata',0.2

  UNION ALL SELECT 'Saltimbocca alla Romana','Fettine di vitello',180
  UNION ALL SELECT 'Saltimbocca alla Romana','Prosciutto crudo',25
  UNION ALL SELECT 'Saltimbocca alla Romana','Salvia',2
  UNION ALL SELECT 'Saltimbocca alla Romana','Burro',10
  UNION ALL SELECT 'Saltimbocca alla Romana','Vino bianco',30
  UNION ALL SELECT 'Saltimbocca alla Romana','Sale',1

  UNION ALL SELECT 'Branzino al Forno','Branzino',250
  UNION ALL SELECT 'Branzino al Forno','Patate',150
  UNION ALL SELECT 'Branzino al Forno','Olio extravergine d\'oliva',10
  UNION ALL SELECT 'Branzino al Forno','Aglio',2
  UNION ALL SELECT 'Branzino al Forno','Prezzemolo',2
  UNION ALL SELECT 'Branzino al Forno','Limone',20
  UNION ALL SELECT 'Branzino al Forno','Sale',1
) q ON q.titolo = r.titolo
JOIN ingredienti i ON i.nome = q.ingr
ON DUPLICATE KEY UPDATE
  quantita_per_persona = VALUES(quantita_per_persona);

-- Vini
INSERT INTO vini (nome, descrizione, tipo, nazione, regione, prezzo_per_bottiglia) VALUES
('Frascati Superiore', 'Bianco fresco e profumato del Lazio.', 'Bianco', 'Italia', 'Lazio', 10.00),
('Chianti Classico', 'Rosso con note di ciliegia e spezie.', 'Rosso', 'Italia', 'Toscana', 14.50),
('Verdicchio dei Castelli di Jesi', 'Bianco con note floreali e mandorla.', 'Bianco', 'Italia', 'Marche', 12.00),
('Prosecco Valdobbiadene', 'Spumante fresco e fruttato.', 'Spumante', 'Italia', 'Veneto', 11.00)
ON DUPLICATE KEY UPDATE
  descrizione = VALUES(descrizione),
  prezzo_per_bottiglia = VALUES(prezzo_per_bottiglia);

-- Abbinamenti ricette-vini
INSERT INTO ricette_vini (ricetta_id, vino_id, annata)
SELECT r.id, v.id, rv.annata
FROM ricette r
JOIN vini v ON (
  (r.titolo = 'Spaghetti alla Carbonara' AND v.nome = 'Frascati Superiore') OR
  (r.titolo = 'Risotto alla Milanese' AND v.nome = 'Prosecco Valdobbiadene') OR
  (r.titolo = 'Lasagne alla Bolognese' AND v.nome = 'Chianti Classico') OR
  (r.titolo = 'Saltimbocca alla Romana' AND v.nome = 'Chianti Classico') OR
  (r.titolo = 'Branzino al Forno' AND v.nome = 'Verdicchio dei Castelli di Jesi')
)
JOIN (
  SELECT 'Spaghetti alla Carbonara' AS titolo, 'Frascati Superiore' AS vino, 2022 AS annata
  UNION ALL SELECT 'Risotto alla Milanese','Prosecco Valdobbiadene',2023
  UNION ALL SELECT 'Lasagne alla Bolognese','Chianti Classico',2021
  UNION ALL SELECT 'Saltimbocca alla Romana','Chianti Classico',2021
  UNION ALL SELECT 'Branzino al Forno','Verdicchio dei Castelli di Jesi',2022
) rv ON rv.titolo = r.titolo AND rv.vino = v.nome
ON DUPLICATE KEY UPDATE
  annata = VALUES(annata);
