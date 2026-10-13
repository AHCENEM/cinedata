-- =========================================================
-- CinéData - 06_transactions.sql : procédure stockée et transactions (TCL)
-- =========================================================
SET NAMES utf8mb4;
USE cinedata;

DELIMITER $$

DROP PROCEDURE IF EXISTS reserver_place $$

CREATE PROCEDURE reserver_place(
  IN  p_id_client        INT,
  IN  p_id_seance        INT,
  IN  p_rangee           CHAR(2),
  IN  p_numero           INT,
  IN  p_tarif            VARCHAR(10),
  IN  p_paiement_accepte BOOLEAN,      -- simule la réponse du système de paiement
  OUT p_message          VARCHAR(255)
)
proc: BEGIN
  DECLARE v_id_salle  INT DEFAULT NULL;
  DECLARE v_prix_base DECIMAL(6,2);
  DECLARE v_classif   VARCHAR(15);
  DECLARE v_age       INT;
  DECLARE v_age_min   INT;
  DECLARE v_id_siege  INT DEFAULT NULL;
  DECLARE v_deja      INT DEFAULT 0;
  DECLARE v_id_resa   INT;
  DECLARE v_prix      DECIMAL(6,2);

  -- Gestionnaire d'erreur : toute erreur SQL imprévue annule la transaction
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_message = 'ERREUR technique : transaction annulée (ROLLBACK)';
  END;

  START TRANSACTION;

  -- 1. La séance existe-t-elle ?
  SELECT se.id_salle, se.prix_base, f.classification
    INTO v_id_salle, v_prix_base, v_classif
  FROM seance se JOIN film f ON f.id = se.id_film
  WHERE se.id = p_id_seance;

  IF v_id_salle IS NULL THEN
    ROLLBACK;
    SET p_message = CONCAT('REFUS : la séance ', p_id_seance, ' n''existe pas');
    LEAVE proc;
  END IF;

  -- 2. Règle R6 : le client a-t-il l'âge requis ?
  SELECT TIMESTAMPDIFF(YEAR, p.date_naissance, CURDATE()) INTO v_age
  FROM personne p WHERE p.id = p_id_client;

  SET v_age_min = CASE v_classif
                    WHEN '-12' THEN 12
                    WHEN '-16' THEN 16
                    WHEN '-18' THEN 18
                    ELSE 0
                  END;

  IF v_age < v_age_min THEN
    ROLLBACK;
    SET p_message = CONCAT('REFUS (R6) : film ', v_classif, ', le client a ', v_age, ' ans');
    LEAVE proc;
  END IF;

  -- 3. Le siège existe-t-il dans la salle de cette séance ?
  SELECT id INTO v_id_siege
  FROM siege
  WHERE id_salle = v_id_salle AND rangee = p_rangee AND numero = p_numero;

  IF v_id_siege IS NULL THEN
    ROLLBACK;
    SET p_message = CONCAT('REFUS : le siège ', p_rangee, p_numero, ' n''existe pas dans cette salle');
    LEAVE proc;
  END IF;

  -- 4. Règle R1 : le siège est-il libre pour cette séance ?
  SELECT COUNT(*) INTO v_deja
  FROM place_reservee
  WHERE id_seance = p_id_seance AND id_siege = v_id_siege;

  IF v_deja > 0 THEN
    ROLLBACK;
    SET p_message = CONCAT('REFUS (R1) : le siège ', p_rangee, p_numero, ' est déjà réservé');
    LEAVE proc;
  END IF;

  -- 5. Création de la réservation, puis point de sauvegarde
  INSERT INTO reservation (statut, id_client, id_seance)
  VALUES ('en attente', p_id_client, p_id_seance);
  SET v_id_resa = LAST_INSERT_ID();

  SAVEPOINT reservation_creee;

  -- 6. Ajout de la place, prix calculé selon le tarif (R5 : -20 % en réduit)
  SET v_prix = CASE p_tarif
                 WHEN 'plein'  THEN v_prix_base
                 WHEN 'reduit' THEN ROUND(v_prix_base * 0.80, 2)
                 ELSE ROUND(v_prix_base * 0.60, 2)
               END;

  INSERT INTO place_reservee (id_reservation, id_siege, id_seance, tarif, prix)
  VALUES (v_id_resa, v_id_siege, p_id_seance, p_tarif, v_prix);

  -- 7. Paiement
  IF p_paiement_accepte THEN
    INSERT INTO paiement (montant, statut, moyen, numero_transaction, id_reservation)
    VALUES (v_prix, 'accepté', 'CB', CONCAT('TX-', LPAD(v_id_resa, 6, '0')), v_id_resa);

    UPDATE reservation SET statut = 'confirmée' WHERE id = v_id_resa;

    INSERT INTO ticket (code, id_reservation)
    VALUES (CONCAT('TCK-', LPAD(v_id_resa, 5, '0')), v_id_resa);

    COMMIT;
    SET p_message = CONCAT('OK : réservation ', v_id_resa, ' confirmée, siège ',
                           p_rangee, p_numero, ', ', v_prix, ' €');
  ELSE
    -- On revient au point de sauvegarde : la place est annulée, la réservation reste
    ROLLBACK TO SAVEPOINT reservation_creee;

    UPDATE reservation SET statut = 'annulée' WHERE id = v_id_resa;

    INSERT INTO paiement (montant, statut, moyen, numero_transaction, id_reservation)
    VALUES (v_prix, 'refusé', 'CB', CONCAT('TX-', LPAD(v_id_resa, 6, '0')), v_id_resa);

    COMMIT;
    SET p_message = CONCAT('PAIEMENT REFUSÉ : réservation ', v_id_resa,
                           ' annulée, siège libéré');
  END IF;
END proc $$

DELIMITER ;

-- =========================================================
-- TESTS
-- =========================================================

-- Un client de test : Léo, 11 ans (pour tester la règle R6)
INSERT IGNORE INTO personne (id, nom, prenom, date_naissance, email)
VALUES (14, 'Petit', 'Léo', '2015-03-10', 'leo.petit@mail.fr');
INSERT IGNORE INTO client (id, adresse) VALUES (14, '2 rue des Écoles, 75005 Paris');

-- T1. Succès : Marco réserve L1 pour « Point de Rupture » (séance 11, film -16)
CALL reserver_place(8, 11, 'L', 1, 'plein', TRUE, @msg);
SELECT 'T1 succès' AS test, @msg AS resultat;

-- T2. Siège déjà pris : Julie veut le même siège L1
CALL reserver_place(2, 11, 'L', 1, 'plein', TRUE, @msg);
SELECT 'T2 siège pris' AS test, @msg AS resultat;

-- T3. Règle R6 : Léo (11 ans) veut voir un film -16
CALL reserver_place(14, 11, 'L', 2, 'plein', TRUE, @msg);
SELECT 'T3 âge' AS test, @msg AS resultat;

-- T4. Paiement refusé : ROLLBACK TO SAVEPOINT
CALL reserver_place(3, 11, 'M', 5, 'reduit', FALSE, @msg);
SELECT 'T4 paiement refusé' AS test, @msg AS resultat;

-- T5. Séance inexistante
CALL reserver_place(1, 999, 'A', 1, 'plein', TRUE, @msg);
SELECT 'T5 séance' AS test, @msg AS resultat;

-- T6. Siège inexistant (rangée Z, n°99)
CALL reserver_place(1, 11, 'Z', 99, 'plein', TRUE, @msg);
SELECT 'T6 siège inexistant' AS test, @msg AS resultat;

-- T7. Tarif invalide : la contrainte CHECK échoue -> gestionnaire d'erreur -> ROLLBACK
CALL reserver_place(1, 11, 'N', 1, 'vip', TRUE, @msg);
SELECT 'T7 tarif invalide' AS test, @msg AS resultat;

-- Bilan des nouvelles réservations
SELECT r.id AS reservation, r.statut, COUNT(pr.id_siege) AS nb_places,
       pa.statut AS paiement, t.code AS ticket
FROM reservation r
LEFT JOIN place_reservee pr ON pr.id_reservation = r.id
LEFT JOIN paiement pa ON pa.id_reservation = r.id
LEFT JOIN ticket t ON t.id_reservation = r.id
WHERE r.id > 16
GROUP BY r.id, r.statut, pa.statut, t.code;
