-- =========================================================
-- CinéData - 02_alter.sql : évolution de la structure
-- À exécuter APRÈS 01_create.sql
-- =========================================================
USE cinedata;

-- 1. Ajouter une colonne : l'URL de l'affiche du film
ALTER TABLE film ADD COLUMN affiche_url VARCHAR(255) NULL AFTER synopsis;

-- 2. Modifier le type d'une colonne : numéros internationaux plus longs
ALTER TABLE personne MODIFY COLUMN telephone VARCHAR(25);

-- 3. Ajouter une contrainte : un film dure au maximum 10 heures
ALTER TABLE film ADD CONSTRAINT chk_film_duree_max CHECK (duree <= 600);

-- 4. Démonstration complète sur une table de test
CREATE TABLE demo_alter (
  id INT AUTO_INCREMENT PRIMARY KEY,
  libelle VARCHAR(30)
);
INSERT INTO demo_alter (libelle) VALUES ('a'), ('b'), ('c');

-- Renommer une colonne (MariaDB 10.4 : CHANGE COLUMN ancien nouveau type)
ALTER TABLE demo_alter CHANGE COLUMN libelle intitule VARCHAR(50) NOT NULL;

-- Ajouter puis supprimer une contrainte
ALTER TABLE demo_alter ADD CONSTRAINT chk_demo CHECK (CHAR_LENGTH(intitule) >= 1);
ALTER TABLE demo_alter DROP CONSTRAINT chk_demo;

-- TRUNCATE vide la table mais garde sa structure
SELECT COUNT(*) AS avant_truncate FROM demo_alter;
TRUNCATE TABLE demo_alter;
SELECT COUNT(*) AS apres_truncate FROM demo_alter;

-- DROP supprime la table entièrement (structure + données)
DROP TABLE demo_alter;

-- Vérification : la nouvelle colonne apparaît dans film
DESCRIBE film;