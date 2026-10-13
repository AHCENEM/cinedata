-- =========================================================
-- CinéData - 05_update_delete.sql : UPDATE et DELETE
-- Tout est fait dans une TRANSACTION puis annulé (ROLLBACK)
-- => la base retrouve son état d'origine à la fin
-- =========================================================
SET NAMES utf8mb4;
USE cinedata;

START TRANSACTION;

-- ---------------------------------------------------------
-- 1. UPDATE simple : confirmer la réservation 15 (en attente)
--    Bonne pratique : SELECT avant / UPDATE / SELECT après
-- ---------------------------------------------------------
SELECT '1 - avant' AS etape, id, statut FROM reservation WHERE id = 15;
UPDATE reservation SET statut = 'confirmée' WHERE id = 15;
SELECT '1 - après' AS etape, id, statut FROM reservation WHERE id = 15;

-- ---------------------------------------------------------
-- 2. UPDATE avec calcul : +50 points fidélité pour le client 1
-- ---------------------------------------------------------
SELECT '2 - avant' AS etape, numero, points FROM carte_fidelite WHERE id_client = 1;
UPDATE carte_fidelite SET points = points + 50 WHERE id_client = 1;
SELECT '2 - après' AS etape, numero, points FROM carte_fidelite WHERE id_client = 1;

-- ---------------------------------------------------------
-- 3. UPDATE avec jointure : +10 % sur les séances IMAX d'octobre
--    (syntaxe UPDATE ... JOIN propre à MySQL / MariaDB)
-- ---------------------------------------------------------
SELECT '3 - avant' AS etape, se.id, se.date_heure_debut, se.prix_base
FROM seance se JOIN salle sa ON sa.id = se.id_salle
WHERE sa.type = 'IMAX' AND se.date_heure_debut >= '2026-10-01';

UPDATE seance se
JOIN salle sa ON sa.id = se.id_salle
SET se.prix_base = ROUND(se.prix_base * 1.10, 2)
WHERE sa.type = 'IMAX' AND se.date_heure_debut >= '2026-10-01';

SELECT '3 - après' AS etape, se.id, se.date_heure_debut, se.prix_base
FROM seance se JOIN salle sa ON sa.id = se.id_salle
WHERE sa.type = 'IMAX' AND se.date_heure_debut >= '2026-10-01';

-- ---------------------------------------------------------
-- 4. UPDATE conditionnel avec CASE : bonus selon la fidélité
--    3 réservations confirmées ou plus => +100, sinon +10
-- ---------------------------------------------------------
SELECT '4 - avant' AS etape, numero, id_client, points FROM carte_fidelite;
UPDATE carte_fidelite cf
SET cf.points = cf.points + CASE
      WHEN (SELECT COUNT(*) FROM reservation r
            WHERE r.id_client = cf.id_client AND r.statut = 'confirmée') >= 3 THEN 100
      ELSE 10
    END;
SELECT '4 - après' AS etape, numero, id_client, points FROM carte_fidelite;

-- ---------------------------------------------------------
-- 5. UPDATE refusé par une contrainte CHECK (points négatifs)
--    ATTENDU : ERROR 4025 ... chk_carte_points failed
-- ---------------------------------------------------------
UPDATE carte_fidelite SET points = -10 WHERE id_client = 4;

-- ---------------------------------------------------------
-- 6. DELETE simple : supprimer l'avis négatif d'Hugo sur le film 2
-- ---------------------------------------------------------
SELECT '6 - avant' AS etape, COUNT(*) AS nb_avis FROM avis;
DELETE FROM avis WHERE id_client = 6 AND id_film = 2;
SELECT '6 - après' AS etape, COUNT(*) AS nb_avis FROM avis;

-- ---------------------------------------------------------
-- 7. DELETE en CASCADE : supprimer la réservation 15
--    ses places (place_reservee) disparaissent automatiquement
-- ---------------------------------------------------------
SELECT '7 - avant' AS etape, COUNT(*) AS places_resa_15 FROM place_reservee WHERE id_reservation = 15;
DELETE FROM reservation WHERE id = 15;
SELECT '7 - après' AS etape, COUNT(*) AS places_resa_15 FROM place_reservee WHERE id_reservation = 15;

-- ---------------------------------------------------------
-- 8. DELETE bloqué par RESTRICT (règle R8) : un film qui a des séances
--    ATTENDU : ERROR 1451 ... foreign key constraint fails
-- ---------------------------------------------------------
DELETE FROM film WHERE id = 1;

-- ---------------------------------------------------------
-- 9. DELETE autorisé : un film sans séance (Les Ombres du Phare)
--    ses lignes film_genre et casting partent en cascade
-- ---------------------------------------------------------
SELECT '9 - avant' AS etape,
       (SELECT COUNT(*) FROM film) AS nb_films,
       (SELECT COUNT(*) FROM film_genre) AS nb_film_genre,
       (SELECT COUNT(*) FROM casting) AS nb_casting;
DELETE FROM film WHERE id = 6;
SELECT '9 - après' AS etape,
       (SELECT COUNT(*) FROM film) AS nb_films,
       (SELECT COUNT(*) FROM film_genre) AS nb_film_genre,
       (SELECT COUNT(*) FROM casting) AS nb_casting;

-- ---------------------------------------------------------
-- 10. DELETE avec LIMIT (clause de sécurité MySQL / MariaDB)
--     supprime au plus 1 avis de note inférieure à 3, le plus ancien
-- ---------------------------------------------------------
DELETE FROM avis WHERE note < 3 ORDER BY date_avis LIMIT 1;
SELECT '10 - après' AS etape, COUNT(*) AS nb_avis FROM avis;

-- ---------------------------------------------------------
-- 11. Composition salle <>-- siège (règle R9)
--     supprimer une salle supprime ses sièges
-- ---------------------------------------------------------
INSERT INTO salle (id, numero, nom, capacite) VALUES (4, 4, 'Salle test', 20);
INSERT INTO siege (id_salle, rangee, numero) VALUES (4, 'A', 1), (4, 'A', 2);
SELECT '11 - avant' AS etape, COUNT(*) AS sieges_salle_4 FROM siege WHERE id_salle = 4;
DELETE FROM salle WHERE id = 4;
SELECT '11 - après' AS etape, COUNT(*) AS sieges_salle_4 FROM siege WHERE id_salle = 4;

-- ---------------------------------------------------------
-- FIN : on annule TOUTES les modifications
-- ---------------------------------------------------------
ROLLBACK;

SELECT 'après ROLLBACK' AS etape,
       (SELECT COUNT(*) FROM film) AS nb_films,
       (SELECT COUNT(*) FROM reservation) AS nb_reservations,
       (SELECT COUNT(*) FROM avis) AS nb_avis,
       (SELECT points FROM carte_fidelite WHERE id_client = 1) AS points_client_1;
