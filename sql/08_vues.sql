-- =========================================================
-- CinéData - 08_vues.sql : vues de sécurité et de simplification
-- À EXÉCUTER EN ROOT (création des vues + GRANT)
-- =========================================================
SET NAMES utf8mb4;
USE cinedata;

-- ---------------------------------------------------------
-- VUE 1 (sécurité) : clients avec données personnelles masquées
-- ---------------------------------------------------------
CREATE OR REPLACE VIEW vue_clients_masques AS
SELECT
  c.id                                                         AS id_client,
  p.prenom,
  CONCAT(LEFT(p.nom, 1), '.')                                  AS nom_masque,
  CONCAT(LEFT(p.email, 2), '***', SUBSTRING(p.email, LOCATE('@', p.email))) AS email_masque,
  CONCAT(REPEAT('*', CHAR_LENGTH(p.telephone) - 2), RIGHT(p.telephone, 2))  AS telephone_masque,
  TIMESTAMPDIFF(YEAR, p.date_naissance, CURDATE())             AS age,
  REGEXP_SUBSTR(c.adresse, '[0-9]{5}')                         AS code_postal,
  c.date_inscription
FROM client c
JOIN personne p ON p.id = c.id;

-- ---------------------------------------------------------
-- VUE 2 (simplicité) : le détail complet de chaque place réservée
--   (reprend la requête Q16 : 6 tables jointes)
-- ---------------------------------------------------------
CREATE OR REPLACE VIEW vue_details_reservation AS
SELECT
  r.id                                AS reservation,
  r.date_reservation,
  r.statut,
  CONCAT(p.prenom, ' ', p.nom)        AS client,
  f.titre                             AS film,
  se.date_heure_debut                 AS seance,
  sa.nom                              AS salle,
  CONCAT(si.rangee, si.numero)        AS siege,
  pr.tarif,
  pr.prix
FROM reservation r
JOIN personne p        ON p.id  = r.id_client
JOIN seance se         ON se.id = r.id_seance
JOIN film f            ON f.id  = se.id_film
JOIN salle sa          ON sa.id = se.id_salle
JOIN place_reservee pr ON pr.id_reservation = r.id
JOIN siege si          ON si.id = pr.id_siege;

-- ---------------------------------------------------------
-- VUE 3 (indicateur) : taux de remplissage de chaque séance
--   (l'attribut dérivé /tauxRemplissage, calculé et non stocké)
-- ---------------------------------------------------------
CREATE OR REPLACE VIEW vue_stats_seances AS
SELECT
  se.id                                           AS id_seance,
  se.date_heure_debut,
  f.titre                                         AS film,
  sa.nom                                          AS salle,
  sa.capacite,
  COUNT(r.id)                                     AS places_vendues,
  COALESCE(SUM(CASE WHEN r.id IS NOT NULL THEN pr.prix END), 0) AS chiffre_affaires,
  ROUND(COUNT(r.id) / sa.capacite * 100, 2)       AS taux_remplissage_pct
FROM seance se
JOIN film f  ON f.id  = se.id_film
JOIN salle sa ON sa.id = se.id_salle
LEFT JOIN place_reservee pr ON pr.id_seance = se.id
LEFT JOIN reservation r     ON r.id = pr.id_reservation AND r.statut = 'confirmée'
GROUP BY se.id, se.date_heure_debut, f.titre, sa.nom, sa.capacite;

-- ---------------------------------------------------------
-- Droits sur les vues
-- ---------------------------------------------------------
GRANT SELECT ON cinedata.vue_clients_masques TO role_analyste;
GRANT SELECT ON cinedata.vue_stats_seances   TO role_analyste;
-- (le manager a déjà SELECT sur toute la base, donc sur les vues)

-- ---------------------------------------------------------
-- Vérifications
-- ---------------------------------------------------------
SHOW FULL TABLES WHERE Table_type = 'VIEW';

SELECT * FROM vue_clients_masques;

SELECT * FROM vue_details_reservation WHERE reservation = 9;

SELECT id_seance, film, salle, places_vendues, chiffre_affaires, taux_remplissage_pct
FROM vue_stats_seances
ORDER BY taux_remplissage_pct DESC;

SHOW GRANTS FOR role_analyste;
