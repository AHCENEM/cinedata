-- =========================================================
-- CinéData - 03_seed.sql : jeu de données de test (DML)
-- À exécuter sur une base vide, APRÈS 01_create.sql et 02_alter.sql
-- Pour recommencer : relancer 01_create.sql, 02_alter.sql, puis ce script
-- =========================================================
SET NAMES utf8mb4;
USE cinedata;

-- ===================== PERSONNES =====================
INSERT INTO personne (id, nom, prenom, date_naissance, email, telephone) VALUES
  (1,  'Benali',   'Karim',    '1990-04-12', 'karim.benali@mail.fr',      '0612345601'),
  (2,  'Martin',   'Julie',    '1985-09-30', 'julie.martin@mail.fr',      '0612345602'),
  (3,  'Dubois',   'Thomas',   '2001-02-17', 'thomas.dubois@mail.fr',     '0612345603'),
  (4,  'Nguyen',   'Linh',     '1995-07-08', 'linh.nguyen@mail.fr',       '0612345604'),
  (5,  'Moreau',   'Sofia',    '2010-05-21', 'sofia.moreau@mail.fr',      '0612345605'),
  (6,  'Lefèvre',  'Hugo',     '1978-11-03', 'hugo.lefevre@mail.fr',      '0612345606'),
  (7,  'Diallo',   'Aminata',  '1999-12-25', 'aminata.diallo@mail.fr',    '0612345607'),
  (8,  'Rossi',    'Marco',    '1988-06-14', 'marco.rossi@mail.fr',       '0612345608'),
  (9,  'Garnier',  'Hélène',   '1975-03-02', 'helene.garnier@cinedata.fr','0612345609'),
  (10, 'Petit',    'Nicolas',  '1982-08-19', 'nicolas.petit@cinedata.fr', '0612345610'),
  (11, 'Haddad',   'Yasmine',  '1998-01-11', 'yasmine.haddad@cinedata.fr','0612345611'),
  (12, 'Leroy',    'Julien',   '2000-10-05', 'julien.leroy@cinedata.fr',  '0612345612'),
  (13, 'Fontaine', 'Paul',     '1992-04-27', 'paul.fontaine@cinedata.fr', '0612345613');

INSERT INTO client (id, adresse, date_inscription) VALUES
  (1, '12 rue Oberkampf, 75011 Paris',          '2024-11-02'),
  (2, '5 avenue Jean Jaurès, 93100 Montreuil',  '2025-02-14'),
  (3, '8 rue de la Paix, 92100 Boulogne',       '2025-05-20'),
  (4, '21 boulevard Voltaire, 75011 Paris',     '2025-01-08'),
  (5, '3 rue des Lilas, 94300 Vincennes',       '2026-03-30'),
  (6, '17 rue Lecourbe, 75015 Paris',           '2024-12-12'),
  (7, '9 place d''Italie, 75013 Paris',         '2026-09-10'),
  (8, '44 rue du Bac, 75007 Paris',             '2026-06-01');

INSERT INTO equipe (id, nom) VALUES
  (1, 'Accueil et caisse'),
  (2, 'Technique');

-- Hiérarchie : Garnier (directrice) > Petit (resp. caisse) > Haddad, Leroy ; Garnier > Fontaine
INSERT INTO employe (id, date_embauche, poste, salaire, id_responsable, id_equipe) VALUES
  (9,  '2015-01-05', 'Directrice',         4200.00, NULL, NULL),
  (10, '2018-03-01', 'Responsable caisse', 2600.00, 9,    1),
  (11, '2022-06-15', 'Caissière',          1900.00, 10,   1),
  (12, '2024-09-01', 'Caissier',           1850.00, 10,   1),
  (13, '2020-02-10', 'Projectionniste',    2100.00, 9,    2);

INSERT INTO carte_fidelite (numero, points, date_creation, id_client) VALUES
  ('CF-0001', 120, '2025-01-10', 1),
  ('CF-0002',  40, '2025-06-02', 4),
  ('CF-0003',   0, '2026-09-15', 7);

-- ===================== CATALOGUE =====================
INSERT INTO realisateur (id, nom, prenom) VALUES
  (1, 'Vasseur',  'Claire'),
  (2, 'Benhamou', 'Malik'),
  (3, 'Roche',    'Inès'),
  (4, 'Morita',   'Kenji'),
  (5, 'Arnaud',   'Paul');

INSERT INTO genre (id, libelle) VALUES
  (1, 'Science-fiction'), (2, 'Aventure'), (3, 'Drame'), (4, 'Thriller'),
  (5, 'Animation'), (6, 'Famille'), (7, 'Policier');

INSERT INTO film (id, titre, duree, date_sortie, classification, synopsis, id_realisateur) VALUES
  (1, 'Les Dunes d''Argent',        155, '2026-09-02', 'Tous publics', 'Une expédition traverse un désert extraterrestre.', 1),
  (2, 'Le Secret de Monte-Verde',   170, '2026-08-26', 'Tous publics', 'Un marin emprisonné prépare sa vengeance.', 2),
  (3, 'Nuit Blanche à Marseille',   105, '2026-09-16', '-12',          'Une commissaire enquête sur un vol de tableaux.', 3),
  (4, 'Le Jardin des Lucioles',      95, '2026-07-08', 'Tous publics', 'Deux enfants découvrent un monde caché.', 4),
  (5, 'Point de Rupture',           128, '2026-10-07', '-16',          'Un ingénieur découvre une faille mortelle.', 5),
  (6, 'Les Ombres du Phare',        112, '2026-11-25', '-12',          'Une gardienne de phare reçoit d''étranges signaux.', 1);

-- Association N:M film <-> genre
INSERT INTO film_genre (id_film, id_genre) VALUES
  (1, 1), (1, 2), (2, 2), (2, 3), (3, 4), (3, 7), (4, 5), (4, 6), (5, 4), (6, 3);

INSERT INTO acteur (id, nom, prenom) VALUES
  (1, 'Mercier', 'Lucas'), (2, 'Lambert', 'Nora'), (3, 'Talbi', 'Samir'),
  (4, 'Girard',  'Emma'),  (5, 'Hamel',   'Victor'), (6, 'Perrin', 'Chloé');

-- Classe d'association casting (avec le rôle)
INSERT INTO casting (id_film, id_acteur, role) VALUES
  (1, 1, 'Elian'), (1, 2, 'Sela'), (2, 3, 'Edmond Varga'), (2, 4, 'Mercedes'),
  (3, 5, 'Commissaire Royer'), (3, 2, 'Léa'), (5, 1, 'Max'), (5, 6, 'Dr Weiss'),
  (6, 4, 'La gardienne');

INSERT INTO avis (note, commentaire, date_avis, id_client, id_film) VALUES
  (5, 'Visuellement incroyable.',          '2026-09-08', 1, 1),
  (4, 'Très bon, un peu long.',            '2026-09-07', 2, 1),
  (3, 'Intrigue correcte.',                '2026-09-22', 3, 3),
  (5, 'Magnifique, mes enfants ont adoré.','2026-10-05', 4, 4),
  (2, 'Je me suis ennuyé.',                '2026-09-14', 6, 2),
  (4, 'Belle adaptation.',                 '2026-09-13', 1, 2);

-- ===================== PROGRAMMATION =====================
INSERT INTO salle (id, numero, nom, capacite, type) VALUES
  (1, 1, 'Méliès',  120, 'standard'),
  (2, 2, 'Lumière', 180, '3D'),
  (3, 3, 'Odyssée', 300, 'IMAX');

-- Génération des 600 sièges avec INSERT ... SELECT et CROSS JOIN
-- Table d'aide : les chiffres de 0 à 9
CREATE TABLE chiffres (n INT);
INSERT INTO chiffres VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9);

-- Méliès : 10 rangées (A à J) x 12 sièges ; A1 et A2 réservés PMR
INSERT INTO siege (id_salle, rangee, numero, est_pmr)
SELECT 1, CHAR(65 + r.v USING utf8mb4), s.v, (r.v = 0 AND s.v <= 2)
FROM (SELECT d1.n * 10 + d2.n AS v FROM chiffres d1 CROSS JOIN chiffres d2) AS r
CROSS JOIN (SELECT d1.n * 10 + d2.n + 1 AS v FROM chiffres d1 CROSS JOIN chiffres d2) AS s
WHERE r.v < 10 AND s.v <= 12
ORDER BY r.v, s.v;

-- Lumière : 10 rangées (A à J) x 18 sièges
INSERT INTO siege (id_salle, rangee, numero, est_pmr)
SELECT 2, CHAR(65 + r.v USING utf8mb4), s.v, (r.v = 0 AND s.v <= 2)
FROM (SELECT d1.n * 10 + d2.n AS v FROM chiffres d1 CROSS JOIN chiffres d2) AS r
CROSS JOIN (SELECT d1.n * 10 + d2.n + 1 AS v FROM chiffres d1 CROSS JOIN chiffres d2) AS s
WHERE r.v < 10 AND s.v <= 18
ORDER BY r.v, s.v;

-- Odyssée : 15 rangées (A à O) x 20 sièges
INSERT INTO siege (id_salle, rangee, numero, est_pmr)
SELECT 3, CHAR(65 + r.v USING utf8mb4), s.v, (r.v = 0 AND s.v <= 2)
FROM (SELECT d1.n * 10 + d2.n AS v FROM chiffres d1 CROSS JOIN chiffres d2) AS r
CROSS JOIN (SELECT d1.n * 10 + d2.n + 1 AS v FROM chiffres d1 CROSS JOIN chiffres d2) AS s
WHERE r.v < 15 AND s.v <= 20
ORDER BY r.v, s.v;

DROP TABLE chiffres;

INSERT INTO seance (id, date_heure_debut, version, prix_base, id_film, id_salle) VALUES
  (1,  '2026-09-05 20:00:00', 'VF',     11.50, 1, 3),
  (2,  '2026-09-06 14:00:00', 'VF',      9.50, 4, 1),
  (3,  '2026-09-12 20:30:00', 'VOSTFR', 10.50, 2, 2),
  (4,  '2026-09-19 21:00:00', 'VF',     10.00, 3, 1),
  (5,  '2026-09-26 18:00:00', 'VF',     11.50, 1, 3),
  (6,  '2026-10-03 20:00:00', 'VF',     10.50, 2, 2),
  (7,  '2026-10-04 15:00:00', 'VF',      9.50, 4, 1),
  (8,  '2026-10-10 21:00:00', 'VOSTFR', 10.50, 5, 2),
  (9,  '2026-10-11 20:00:00', 'VF',     11.50, 1, 3),
  (10, '2026-10-17 21:30:00', 'VF',     10.00, 3, 1),
  (11, '2026-10-24 20:00:00', 'VF',     12.00, 5, 3),
  (12, '2026-10-25 14:30:00', 'VF',      9.50, 4, 1);

-- ===================== BILLETTERIE =====================
INSERT INTO reservation (id, date_reservation, statut, id_client, id_seance) VALUES
  (1,  '2026-09-01 10:12:00', 'confirmée',  1, 1),
  (2,  '2026-09-02 18:40:00', 'confirmée',  2, 1),
  (3,  '2026-09-04 09:05:00', 'confirmée',  6, 2),
  (4,  '2026-09-10 12:30:00', 'confirmée',  3, 3),
  (5,  '2026-09-11 20:15:00', 'confirmée',  1, 3),
  (6,  '2026-09-17 08:50:00', 'confirmée',  4, 4),
  (7,  '2026-09-20 16:00:00', 'annulée',    7, 5),
  (8,  '2026-09-24 11:11:00', 'confirmée',  7, 5),
  (9,  '2026-09-30 19:00:00', 'confirmée',  2, 6),
  (10, '2026-10-01 10:00:00', 'confirmée',  4, 7),
  (11, '2026-10-02 13:45:00', 'confirmée',  6, 7),
  (12, '2026-10-08 17:30:00', 'confirmée',  1, 8),
  (13, '2026-10-09 21:00:00', 'confirmée',  3, 8),
  (14, '2026-10-09 22:10:00', 'confirmée',  5, 9),
  (15, '2026-10-12 09:30:00', 'en attente', 7, 11),
  (16, '2026-10-12 14:20:00', 'confirmée',  4, 9);

-- Places : table d'aide (réservation, rangée, numéro, tarif)
CREATE TABLE tmp_places (id_reservation INT, rangee CHAR(2), numero INT, tarif VARCHAR(10));
INSERT INTO tmp_places VALUES
  (1,'F',10,'plein'), (1,'F',11,'reduit'),
  (2,'G',5,'plein'),
  (3,'C',3,'plein'), (3,'C',4,'enfant'), (3,'C',5,'enfant'),
  (4,'E',7,'plein'), (4,'E',8,'plein'),
  (5,'E',9,'reduit'),
  (6,'D',6,'reduit'),
  (8,'H',1,'plein'), (8,'H',2,'reduit'),
  (9,'B',8,'plein'), (9,'B',9,'plein'), (9,'B',10,'plein'), (9,'B',11,'plein'),
  (10,'A',1,'reduit'), (10,'A',2,'enfant'),
  (11,'D',4,'plein'), (11,'D',5,'enfant'), (11,'D',6,'enfant'),
  (12,'F',9,'reduit'),
  (13,'F',10,'plein'),
  (14,'K',12,'plein'),
  (15,'J',5,'plein'), (15,'J',6,'plein'),
  (16,'K',13,'reduit');

-- INSERT ... SELECT : on retrouve le siège et la séance, et on calcule le prix selon le tarif
INSERT INTO place_reservee (id_reservation, id_siege, id_seance, tarif, prix)
SELECT t.id_reservation,
       si.id,
       r.id_seance,
       t.tarif,
       CASE t.tarif
         WHEN 'plein'  THEN se.prix_base
         WHEN 'reduit' THEN ROUND(se.prix_base * 0.80, 2)   -- R5 : -20 %
         ELSE ROUND(se.prix_base * 0.60, 2)                 -- tarif enfant
       END
FROM tmp_places t
JOIN reservation r ON r.id = t.id_reservation
JOIN seance se     ON se.id = r.id_seance
JOIN siege si      ON si.id_salle = se.id_salle AND si.rangee = t.rangee AND si.numero = t.numero;

DROP TABLE tmp_places;

-- Paiements par carte : montant = somme des places (INSERT ... SELECT avec GROUP BY)
INSERT INTO paiement (montant, date_paiement, statut, moyen, numero_transaction, id_reservation)
SELECT SUM(p.prix), DATE_ADD(r.date_reservation, INTERVAL 2 MINUTE), 'accepté', 'CB',
       CONCAT('TX-', LPAD(r.id, 6, '0')), r.id
FROM reservation r
JOIN place_reservee p ON p.id_reservation = r.id
WHERE r.statut = 'confirmée' AND r.id NOT IN (3, 11)
GROUP BY r.id, r.date_reservation;

-- Paiements en espèces au guichet (réservations 3 et 11)
INSERT INTO paiement (montant, date_paiement, statut, moyen, montant_recu, id_reservation)
SELECT SUM(p.prix), DATE_ADD(r.date_reservation, INTERVAL 2 MINUTE), 'accepté', 'ESPECES',
       CEILING(SUM(p.prix) / 5) * 5, r.id
FROM reservation r
JOIN place_reservee p ON p.id_reservation = r.id
WHERE r.id IN (3, 11)
GROUP BY r.id, r.date_reservation;

-- Paiement refusé (réservation 7, annulée)
INSERT INTO paiement (montant, date_paiement, statut, moyen, numero_transaction, id_reservation) VALUES
  (23.00, '2026-09-20 16:02:00', 'refusé', 'CB', 'TX-000007', 7);

-- Un ticket par réservation confirmée
INSERT INTO ticket (code, date_emission, id_reservation)
SELECT CONCAT('TCK-', LPAD(r.id, 5, '0')), DATE_ADD(r.date_reservation, INTERVAL 3 MINUTE), r.id
FROM reservation r
WHERE r.statut = 'confirmée';

-- ===================== VÉRIFICATION =====================
SELECT 'personne' AS nom_table, COUNT(*) AS nb_lignes FROM personne
UNION ALL SELECT 'client',         COUNT(*) FROM client
UNION ALL SELECT 'employe',        COUNT(*) FROM employe
UNION ALL SELECT 'film',           COUNT(*) FROM film
UNION ALL SELECT 'seance',         COUNT(*) FROM seance
UNION ALL SELECT 'siege',          COUNT(*) FROM siege
UNION ALL SELECT 'reservation',    COUNT(*) FROM reservation
UNION ALL SELECT 'place_reservee', COUNT(*) FROM place_reservee
UNION ALL SELECT 'paiement',       COUNT(*) FROM paiement
UNION ALL SELECT 'ticket',         COUNT(*) FROM ticket;