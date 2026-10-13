-- =========================================================
-- CinéData - 10_objet_relationnel.sql (PostgreSQL 18)
-- Notions objet-relationnel : types composés, ENUM, héritage (INHERITS),
-- polymorphisme, tableaux, JSONB, fonctions-méthodes, trigger PL/pgSQL
-- À lancer connecté à la base "postgres" (le script crée cinedata_pg)
-- =========================================================
SET client_encoding = 'UTF8';

DROP DATABASE IF EXISTS cinedata_pg;
CREATE DATABASE cinedata_pg ENCODING 'UTF8';
\c cinedata_pg
SET client_encoding = 'UTF8';

-- #########################################################
-- 1. TYPES PERSONNALISÉS
-- #########################################################

-- Type composé : une adresse est UN objet avec 3 attributs
CREATE TYPE adresse_t AS (
  rue         VARCHAR(100),
  code_postal CHAR(5),
  ville       VARCHAR(50)
);

-- Énumération : seulement 4 valeurs possibles
CREATE TYPE classification_t AS ENUM ('Tous publics', '-12', '-16', '-18');

-- #########################################################
-- 2. HÉRITAGE NATIF : personne -> client / employe
-- #########################################################

-- Table "mère" : les attributs communs
CREATE TABLE personne (
  id             SERIAL,
  nom            VARCHAR(50)  NOT NULL,
  prenom         VARCHAR(50)  NOT NULL,
  date_naissance DATE,
  email          VARCHAR(100) NOT NULL,
  adresse        adresse_t,                 -- colonne de type composé
  PRIMARY KEY (id),
  UNIQUE (email)
);

-- Tables "filles" : elles héritent de TOUTES les colonnes de personne
CREATE TABLE client (
  date_inscription DATE NOT NULL DEFAULT CURRENT_DATE,
  PRIMARY KEY (id)                          -- la PK n'est PAS héritée : on la redéclare
) INHERITS (personne);

CREATE TABLE employe (
  poste          VARCHAR(50)  NOT NULL,
  salaire        NUMERIC(8,2) CHECK (salaire >= 0),
  id_responsable INT,
  PRIMARY KEY (id),
  FOREIGN KEY (id_responsable) REFERENCES employe(id)
) INHERITS (personne);

-- Insertion : ROW(...)::adresse_t construit un objet adresse
INSERT INTO client (nom, prenom, date_naissance, email, adresse, date_inscription) VALUES
  ('Benali', 'Karim', '1990-04-12', 'karim.benali@mail.fr',
     ROW('12 rue Oberkampf', '75011', 'Paris')::adresse_t, '2024-11-02'),
  ('Martin', 'Julie', '1985-09-30', 'julie.martin@mail.fr',
     ROW('5 avenue Jean Jaurès', '93100', 'Montreuil')::adresse_t, '2025-02-14'),
  ('Moreau', 'Sofia', '2010-05-21', 'sofia.moreau@mail.fr',
     ROW('3 rue des Lilas', '94300', 'Vincennes')::adresse_t, '2026-03-30');

INSERT INTO employe (nom, prenom, date_naissance, email, adresse, poste, salaire, id_responsable) VALUES
  ('Garnier', 'Hélène', '1975-03-02', 'helene.garnier@cinedata.fr',
     ROW('8 rue de Rivoli', '75004', 'Paris')::adresse_t, 'Directrice', 4200, NULL);

INSERT INTO employe (nom, prenom, date_naissance, email, adresse, poste, salaire, id_responsable)
SELECT 'Haddad', 'Yasmine', '1998-01-11', 'yasmine.haddad@cinedata.fr',
       ROW('40 rue de Belleville', '75020', 'Paris')::adresse_t, 'Caissière', 1900, id
FROM employe WHERE nom = 'Garnier';

-- 2a. POLYMORPHISME : interroger la table mère renvoie AUSSI les lignes des filles
--     tableoid::regclass indique de quelle table vient chaque ligne
SELECT '2a - polymorphisme : SELECT FROM personne' AS etape;
SELECT p.id, p.prenom, p.nom, p.tableoid::regclass AS table_origine
FROM personne p
ORDER BY p.id;

-- 2b. ONLY : seulement les lignes stockées dans la table mère elle-même
--     (0 ligne : personne joue le rôle d'une classe abstraite)
SELECT '2b - SELECT FROM ONLY personne' AS etape;
SELECT COUNT(*) AS nb_personnes_pures FROM ONLY personne;

-- 2c. Accès aux attributs du type composé : (colonne).attribut
SELECT '2c - accès au type composé' AS etape;
SELECT prenom, (adresse).ville AS ville, (adresse).code_postal AS cp
FROM personne
ORDER BY (adresse).ville;

-- 2d. Mise à jour d'un seul attribut du type composé
UPDATE client SET adresse.ville = 'Paris', adresse.code_postal = '75020'
WHERE email = 'julie.martin@mail.fr';
SELECT '2d - après UPDATE de adresse.ville' AS etape;
SELECT prenom, adresse FROM client WHERE email = 'julie.martin@mail.fr';

-- 2e. LIMITE DE L'HÉRITAGE PostgreSQL : UNIQUE et PRIMARY KEY ne s'appliquent
--     qu'à CHAQUE table séparément. Un e-mail déjà utilisé par un employé
--     est ACCEPTÉ dans client ! (sous MariaDB, la stratégie C l'empêchait)
INSERT INTO client (nom, prenom, email)
VALUES ('Doublon', 'Test', 'helene.garnier@cinedata.fr');
SELECT '2e - limite : e-mail en double accepté entre tables filles' AS etape;
SELECT email, COUNT(*) AS nb, string_agg(tableoid::regclass::text, ', ') AS tables
FROM personne
GROUP BY email
HAVING COUNT(*) > 1;
DELETE FROM client WHERE nom = 'Doublon';

-- #########################################################
-- 3. MÉTHODES : fonctions qui prennent un objet en paramètre
-- #########################################################

-- Une "méthode" de la classe personne : son âge (l'attribut dérivé /age du diagramme)
CREATE FUNCTION age_annees(p personne) RETURNS INT
LANGUAGE sql IMMUTABLE AS $$
  SELECT EXTRACT(YEAR FROM age(CURRENT_DATE, p.date_naissance))::INT
$$;

-- Une autre méthode : l'adresse complète sur une ligne
CREATE FUNCTION adresse_complete(p personne) RETURNS TEXT
LANGUAGE sql IMMUTABLE AS $$
  SELECT (p.adresse).rue || ', ' || (p.adresse).code_postal || ' ' || (p.adresse).ville
$$;

-- Appel en notation fonctionnelle OU en notation "attribut" (comme une méthode objet)
SELECT '3 - méthodes : p.age_annees et p.adresse_complete' AS etape;
SELECT p.prenom,
       age_annees(p)       AS age_notation_fonction,
       p.age_annees        AS age_notation_methode,
       p.adresse_complete  AS adresse
FROM personne p
ORDER BY p.age_annees DESC;

-- #########################################################
-- 4. TABLEAUX ET JSONB
-- #########################################################

CREATE TABLE film (
  id             SERIAL PRIMARY KEY,
  titre          VARCHAR(150) NOT NULL,
  duree          INT NOT NULL CHECK (duree > 0),
  classification classification_t NOT NULL DEFAULT 'Tous publics',
  tags           TEXT[] NOT NULL DEFAULT '{}',     -- un TABLEAU de mots-clés
  infos          JSONB                             -- des données semi-structurées
);

INSERT INTO film (titre, duree, classification, tags, infos) VALUES
  ('Les Dunes d''Argent', 155, 'Tous publics', ARRAY['sf', 'aventure', 'desert'],
     '{"pays": "France", "langues": ["fr", "en"], "budget_millions": 90}'),
  ('Le Secret de Monte-Verde', 170, 'Tous publics', ARRAY['aventure', 'drame', 'vengeance'],
     '{"pays": "France", "langues": ["fr"], "adaptation": true}'),
  ('Nuit Blanche à Marseille', 105, '-12', ARRAY['thriller', 'policier'],
     '{"pays": "France", "langues": ["fr"]}'),
  ('Le Jardin des Lucioles', 95, 'Tous publics', ARRAY['animation', 'famille'],
     '{"pays": "Japon", "langues": ["ja", "fr"], "studio": "Studio Hoshi"}'),
  ('Point de Rupture', 128, '-16', ARRAY['thriller', 'sf'],
     '{"pays": "Belgique", "langues": ["fr", "nl"], "budget_millions": 25}');

-- 4a. ENUM : une valeur hors liste est refusée
SELECT '4a - ENUM : -21 est refusé (erreur attendue ci-dessous)' AS etape;
INSERT INTO film (titre, duree, classification) VALUES ('Test', 100, '-21');

-- 4b. Recherche dans un tableau : ANY et l'opérateur "contient" @>
SELECT '4b - films taggés sf' AS etape;
SELECT titre, tags FROM film WHERE 'sf' = ANY(tags);

SELECT '4b - films taggés thriller ET sf' AS etape;
SELECT titre, tags FROM film WHERE tags @> ARRAY['thriller', 'sf'];

-- 4c. Accès par indice (les tableaux PostgreSQL commencent à 1) et taille
SELECT '4c - premier tag et nombre de tags' AS etape;
SELECT titre, tags[1] AS premier_tag, array_length(tags, 1) AS nb_tags FROM film;

-- 4d. unnest : "déplier" un tableau en lignes, pour compter les tags
SELECT '4d - popularité des tags (unnest)' AS etape;
SELECT tag, COUNT(*) AS nb_films
FROM film, unnest(tags) AS tag
GROUP BY tag
ORDER BY nb_films DESC, tag;

-- 4e. JSONB : ->> extrait un texte, @> teste l'inclusion
SELECT '4e - JSONB : pays et langues' AS etape;
SELECT titre, infos->>'pays' AS pays, infos->'langues' AS langues
FROM film;

SELECT '4e - JSONB : films français' AS etape;
SELECT titre FROM film WHERE infos @> '{"pays": "France"}';

SELECT '4e - JSONB : champ présent seulement pour certains films' AS etape;
SELECT titre, (infos->>'budget_millions')::INT AS budget_millions
FROM film
WHERE infos ? 'budget_millions';

-- #########################################################
-- 5. FONCTION PL/pgSQL + TRIGGER
-- #########################################################

CREATE TABLE salle (
  id       SERIAL PRIMARY KEY,
  nom      VARCHAR(50) NOT NULL,
  capacite INT NOT NULL CHECK (capacite BETWEEN 20 AND 400)
);

CREATE TABLE seance (
  id             SERIAL PRIMARY KEY,
  id_film        INT NOT NULL REFERENCES film(id),
  id_salle       INT NOT NULL REFERENCES salle(id),
  debut          TIMESTAMP NOT NULL,
  places_vendues INT NOT NULL DEFAULT 0        -- mis à jour par le trigger
);

CREATE TABLE billet (
  id        SERIAL PRIMARY KEY,
  id_seance INT NOT NULL REFERENCES seance(id),
  siege     VARCHAR(5) NOT NULL,
  prix      NUMERIC(6,2) NOT NULL CHECK (prix >= 0),
  UNIQUE (id_seance, siege)                   -- R1
);

INSERT INTO salle (nom, capacite) VALUES ('Méliès', 120), ('Petite salle test', 20);
INSERT INTO seance (id_film, id_salle, debut) VALUES
  (1, 1, '2026-10-24 20:00'),
  (4, 2, '2026-10-25 14:30');

-- Fonction : nombre de places restantes pour une séance
CREATE FUNCTION places_restantes(p_id_seance INT) RETURNS INT
LANGUAGE plpgsql AS $$
DECLARE
  v_restantes INT;
BEGIN
  SELECT sa.capacite - se.places_vendues INTO v_restantes
  FROM seance se JOIN salle sa ON sa.id = se.id_salle
  WHERE se.id = p_id_seance;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'La séance % n''existe pas', p_id_seance;
  END IF;

  RETURN v_restantes;
END;
$$;

-- Fonction de trigger : refuse si complet, sinon met à jour le compteur
CREATE FUNCTION fn_billet_vendu() RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
  IF places_restantes(NEW.id_seance) <= 0 THEN
    RAISE EXCEPTION 'Séance % complète : plus aucune place', NEW.id_seance;
  END IF;

  UPDATE seance SET places_vendues = places_vendues + 1 WHERE id = NEW.id_seance;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_billet_vendu
BEFORE INSERT ON billet
FOR EACH ROW EXECUTE FUNCTION fn_billet_vendu();

-- 5a. On vend les 20 places de la petite salle (generate_series génère A1..A20)
INSERT INTO billet (id_seance, siege, prix)
SELECT 2, 'A' || n, 9.50 FROM generate_series(1, 20) AS n;

-- On vend 3 places dans la grande salle
INSERT INTO billet (id_seance, siege, prix) VALUES (1, 'F10', 11.50), (1, 'F11', 11.50), (1, 'F12', 9.20);

SELECT '5a - places restantes (fonction PL/pgSQL)' AS etape;
SELECT se.id AS seance, f.titre, sa.nom AS salle, sa.capacite,
       se.places_vendues, places_restantes(se.id) AS restantes
FROM seance se
JOIN film f  ON f.id  = se.id_film
JOIN salle sa ON sa.id = se.id_salle
ORDER BY se.id;

-- 5b. La 21e place est refusée par le trigger (erreur attendue ci-dessous)
SELECT '5b - 21e place dans une salle de 20 : refusée (erreur attendue ci-dessous)' AS etape;
INSERT INTO billet (id_seance, siege, prix) VALUES (2, 'B1', 9.50);

SELECT '5c - le compteur est resté à 20' AS etape;
SELECT id AS seance, places_vendues FROM seance WHERE id = 2;

-- #########################################################
-- 6. BILAN : la structure de la base
-- #########################################################
SELECT '6 - tables et héritage' AS etape;
SELECT c.relname AS table_fille, p.relname AS table_mere
FROM pg_inherits i
JOIN pg_class c ON c.oid = i.inhrelid
JOIN pg_class p ON p.oid = i.inhparent;

\dT
\dt
