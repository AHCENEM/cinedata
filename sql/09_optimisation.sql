-- =========================================================
-- CinéData - 09_optimisation.sql
-- A. Index et EXPLAIN   B. CTE récursive   C. Triggers   D. Tests automatisés
-- À exécuter avec cinedata_dev
-- =========================================================
SET NAMES utf8mb4;
USE cinedata;

-- #########################################################
-- PARTIE A : INDEX ET EXPLAIN
-- #########################################################
DROP INDEX IF EXISTS idx_siege_rangee_numero ON siege;
ANALYZE TABLE siege;

-- A1. SANS index : MariaDB doit lire toute la table (type = ALL)
SELECT 'A1 - sans index' AS etape;
EXPLAIN SELECT id, id_salle FROM siege WHERE rangee = 'F' AND numero = 10;

-- A2. Création d'un index composé sur (rangee, numero)
CREATE INDEX idx_siege_rangee_numero ON siege(rangee, numero);
ANALYZE TABLE siege;

-- A3. AVEC index : accès direct (type = ref, key = idx_siege_rangee_numero)
SELECT 'A3 - avec index' AS etape;
EXPLAIN SELECT id, id_salle FROM siege WHERE rangee = 'F' AND numero = 10;

-- A4. Piège de l'index composé : chercher sur la 2e colonne SEULE ne l'utilise pas
SELECT 'A4 - numero seul : index inutilisable' AS etape;
EXPLAIN SELECT id, id_salle FROM siege WHERE numero = 10;

-- A5. Index UNIQUE déjà existant sur l'e-mail : accès en une seule ligne (type = const)
SELECT 'A5 - index unique sur email' AS etape;
EXPLAIN SELECT nom FROM personne WHERE email = 'karim.benali@mail.fr';

-- A6. Une jointure : les clés étrangères sont indexées automatiquement par InnoDB
SELECT 'A6 - jointure sur clés étrangères' AS etape;
EXPLAIN SELECT f.titre, COUNT(*)
FROM place_reservee pr
JOIN seance se ON se.id = pr.id_seance
JOIN film f ON f.id = se.id_film
GROUP BY f.id, f.titre;

-- Liste des index de la table siege
SHOW INDEX FROM siege;

-- #########################################################
-- PARTIE B : CTE RÉCURSIVE - L'ORGANIGRAMME
-- #########################################################
SELECT 'B - organigramme (CTE récursive)' AS etape;

WITH RECURSIVE organigramme AS (
  -- Point de départ : les employés sans responsable (niveau 0)
  SELECT e.id,
         CONCAT(p.prenom, ' ', p.nom) AS employe,
         e.poste,
         0 AS niveau,
         CAST(CONCAT(p.prenom, ' ', p.nom) AS CHAR(500)) AS chemin
  FROM employe e
  JOIN personne p ON p.id = e.id
  WHERE e.id_responsable IS NULL

  UNION ALL

  -- Étape récursive : les employés dont le responsable est déjà dans la liste
  SELECT e.id,
         CONCAT(p.prenom, ' ', p.nom),
         e.poste,
         o.niveau + 1,
         CONCAT(o.chemin, ' > ', p.prenom, ' ', p.nom)
  FROM employe e
  JOIN personne p ON p.id = e.id
  JOIN organigramme o ON e.id_responsable = o.id
)
SELECT niveau,
       CONCAT(REPEAT('    ', niveau), employe) AS organigramme,
       poste,
       chemin
FROM organigramme
ORDER BY chemin;

-- #########################################################
-- PARTIE C : TRIGGERS
-- #########################################################

-- Table d'audit pour tracer les changements de prix
CREATE TABLE IF NOT EXISTS historique_prix (
  id INT AUTO_INCREMENT PRIMARY KEY,
  id_seance INT NOT NULL,
  ancien_prix DECIMAL(6,2) NOT NULL,
  nouveau_prix DECIMAL(6,2) NOT NULL,
  date_modification DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  modifie_par VARCHAR(100) NOT NULL
);

DROP TRIGGER IF EXISTS trg_seance_chevauchement;
DROP TRIGGER IF EXISTS trg_place_controles;
DROP TRIGGER IF EXISTS trg_audit_prix;

DELIMITER $$

-- C1. Règle R3 : pas de chevauchement de séances dans une même salle
--     (durée du film + 30 minutes de ménage)
CREATE TRIGGER trg_seance_chevauchement
BEFORE INSERT ON seance
FOR EACH ROW
BEGIN
  DECLARE v_duree_nouveau INT;
  DECLARE v_conflits INT;

  SELECT duree INTO v_duree_nouveau FROM film WHERE id = NEW.id_film;

  SELECT COUNT(*) INTO v_conflits
  FROM seance s
  JOIN film f ON f.id = s.id_film
  WHERE s.id_salle = NEW.id_salle
    AND NEW.date_heure_debut < s.date_heure_debut + INTERVAL (f.duree + 30) MINUTE
    AND s.date_heure_debut < NEW.date_heure_debut + INTERVAL (v_duree_nouveau + 30) MINUTE;

  IF v_conflits > 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'R3 : cette séance chevauche une autre séance dans la même salle';
  END IF;
END $$

-- C2. Règle R2 + cohérence de la dénormalisation (id_seance recopié)
CREATE TRIGGER trg_place_controles
BEFORE INSERT ON place_reservee
FOR EACH ROW
BEGIN
  DECLARE v_seance_resa INT;
  DECLARE v_salle_seance INT;
  DECLARE v_salle_siege INT;
  DECLARE v_nb_places INT;

  -- La séance de la place doit être celle de la réservation
  SELECT id_seance INTO v_seance_resa FROM reservation WHERE id = NEW.id_reservation;
  IF NEW.id_seance <> v_seance_resa THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Incohérence : la séance de la place ne correspond pas à celle de la réservation';
  END IF;

  -- Le siège doit appartenir à la salle de la séance
  SELECT id_salle INTO v_salle_seance FROM seance WHERE id = NEW.id_seance;
  SELECT id_salle INTO v_salle_siege FROM siege WHERE id = NEW.id_siege;
  IF v_salle_siege <> v_salle_seance THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Incohérence : ce siège n''appartient pas à la salle de la séance';
  END IF;

  -- R2 : 10 places maximum par réservation
  SELECT COUNT(*) INTO v_nb_places FROM place_reservee WHERE id_reservation = NEW.id_reservation;
  IF v_nb_places >= 10 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'R2 : une réservation contient au maximum 10 places';
  END IF;
END $$

-- C3. Audit : tracer chaque changement de prix d'une séance
CREATE TRIGGER trg_audit_prix
AFTER UPDATE ON seance
FOR EACH ROW
BEGIN
  IF OLD.prix_base <> NEW.prix_base THEN
    INSERT INTO historique_prix (id_seance, ancien_prix, nouveau_prix, modifie_par)
    VALUES (NEW.id, OLD.prix_base, NEW.prix_base, USER());
  END IF;
END $$

-- #########################################################
-- PARTIE D : PROCÉDURE DE TEST AUTOMATISÉ
-- #########################################################
DROP PROCEDURE IF EXISTS tester $$

CREATE PROCEDURE tester(
  IN p_nom          VARCHAR(100),
  IN p_sql          TEXT,
  IN p_doit_echouer BOOLEAN
)
BEGIN
  DECLARE v_erreur  BOOLEAN DEFAULT FALSE;
  DECLARE v_message VARCHAR(255) DEFAULT '';

  -- Capture de l'erreur éventuelle, sans arrêter la procédure
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
  BEGIN
    SET v_erreur = TRUE;
    GET DIAGNOSTICS CONDITION 1 v_message = MESSAGE_TEXT;
  END;

  SET @requete_test = p_sql;
  PREPARE instruction FROM @requete_test;
  EXECUTE instruction;
  DEALLOCATE PREPARE instruction;

  INSERT INTO resultats_tests (test, attendu, obtenu, statut, message)
  VALUES (p_nom,
          IF(p_doit_echouer, 'erreur', 'succès'),
          IF(v_erreur, 'erreur', 'succès'),
          IF(v_erreur = p_doit_echouer, 'RÉUSSI', 'ÉCHOUÉ'),
          LEFT(v_message, 120));
END $$

DELIMITER ;

-- Table des résultats : MEMORY = non transactionnelle, elle survit au ROLLBACK
DROP TEMPORARY TABLE IF EXISTS resultats_tests;
CREATE TEMPORARY TABLE resultats_tests (
  num INT AUTO_INCREMENT PRIMARY KEY,
  test VARCHAR(100),
  attendu VARCHAR(10),
  obtenu VARCHAR(10),
  statut VARCHAR(10),
  message VARCHAR(150)
) ENGINE = MEMORY;

-- Tous les tests dans une transaction annulée à la fin
START TRANSACTION;

CALL tester('T1  prix négatif (CHECK R5)',
  'UPDATE seance SET prix_base = -5 WHERE id = 1', TRUE);

CALL tester('T2  siège déjà réservé (UNIQUE R1)',
  'INSERT INTO place_reservee (id_reservation, id_siege, id_seance, tarif, prix)
   SELECT 2, id, 1, ''plein'', 11.50 FROM siege WHERE id_salle = 3 AND rangee = ''F'' AND numero = 10', TRUE);

CALL tester('T3  séance qui chevauche (trigger R3)',
  'INSERT INTO seance (date_heure_debut, prix_base, id_film, id_salle)
   VALUES (''2026-10-11 21:00:00'', 10.00, 4, 3)', TRUE);

CALL tester('T4  séance valide un autre jour',
  'INSERT INTO seance (date_heure_debut, prix_base, id_film, id_salle)
   VALUES (''2026-10-30 20:00:00'', 10.00, 4, 3)', FALSE);

CALL tester('T5  plus de 10 places (trigger R2)',
  'INSERT INTO place_reservee (id_reservation, id_siege, id_seance, tarif, prix)
   SELECT 9, id, 6, ''plein'', 10.50 FROM siege WHERE id_salle = 2 AND rangee = ''J''', TRUE);

CALL tester('T6  séance incohérente (trigger)',
  'INSERT INTO place_reservee (id_reservation, id_siege, id_seance, tarif, prix)
   SELECT 1, id, 3, ''plein'', 10.50 FROM siege WHERE id_salle = 2 AND rangee = ''A'' AND numero = 9', TRUE);

CALL tester('T7  siège d''une autre salle (trigger)',
  'INSERT INTO place_reservee (id_reservation, id_siege, id_seance, tarif, prix)
   SELECT 1, id, 1, ''plein'', 11.50 FROM siege WHERE id_salle = 1 AND rangee = ''A'' AND numero = 5', TRUE);

CALL tester('T8  e-mail en double (UNIQUE R10)',
  'INSERT INTO personne (nom, prenom, email) VALUES (''Test'', ''Test'', ''karim.benali@mail.fr'')', TRUE);

CALL tester('T9  avis noté 6 sur 5 (CHECK)',
  'INSERT INTO avis (note, id_client, id_film) VALUES (6, 3, 1)', TRUE);

CALL tester('T10 place valide',
  'INSERT INTO place_reservee (id_reservation, id_siege, id_seance, tarif, prix)
   SELECT 13, id, 8, ''plein'', 10.50 FROM siege WHERE id_salle = 2 AND rangee = ''A'' AND numero = 5', FALSE);

CALL tester('T11 changement de prix valide',
  'UPDATE seance SET prix_base = 11.00 WHERE id = 1', FALSE);

-- L'audit a-t-il enregistré le changement de prix du test T11 ?
SELECT 'C3 - audit du test T11' AS etape;
SELECT id_seance, ancien_prix, nouveau_prix, modifie_par FROM historique_prix;

-- On annule toutes les modifications des tests
ROLLBACK;

-- Résultats des tests (la table MEMORY a survécu au ROLLBACK)
SELECT 'D - bilan des tests' AS etape;
SELECT num, test, attendu, obtenu, statut, message FROM resultats_tests ORDER BY num;

SELECT COUNT(*) AS nb_tests,
       SUM(statut = 'RÉUSSI') AS reussis,
       SUM(statut = 'ÉCHOUÉ') AS echoues
FROM resultats_tests;
