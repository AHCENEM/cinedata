-- =========================================================
-- CinéData - 04_requetes.sql : interrogation des données
-- =========================================================
SET NAMES utf8mb4;
USE cinedata;

-- ========== NIVEAU 1 : SELECT, WHERE, ORDER BY, LIMIT ==========

-- Q1. Tous les films, du plus long au plus court
SELECT titre, duree, classification FROM film ORDER BY duree DESC;

-- Q2. Films de plus de 2 heures (opérateur >)
SELECT titre, duree FROM film WHERE duree > 120;

-- Q3. Clients habitant Paris (LIKE)
SELECT p.prenom, p.nom, c.adresse
FROM client c JOIN personne p ON p.id = c.id
WHERE c.adresse LIKE '%Paris%';

-- Q4. Séances du mois d'octobre (BETWEEN)
SELECT id, date_heure_debut, prix_base FROM seance
WHERE date_heure_debut BETWEEN '2026-10-01' AND '2026-10-31 23:59:59';

-- Q5. Films déconseillés aux moins de 12 ou 16 ans (IN)
SELECT titre, classification FROM film WHERE classification IN ('-12', '-16');

-- Q6. Employés sans responsable (IS NULL)
SELECT id, poste FROM employe WHERE id_responsable IS NULL;

-- Q7. Les 3 séances les plus chères (LIMIT)
SELECT id, date_heure_debut, prix_base FROM seance ORDER BY prix_base DESC LIMIT 3;

-- ========== NIVEAU 2 : AGRÉGATIONS ==========

-- Q8. Statistiques sur les films (COUNT, AVG, MIN, MAX)
SELECT COUNT(*) AS nb_films, ROUND(AVG(duree)) AS duree_moyenne,
       MIN(duree) AS plus_court, MAX(duree) AS plus_long
FROM film;

-- Q9. Nombre de séances par salle (GROUP BY)
SELECT sa.nom AS salle, COUNT(se.id) AS nb_seances
FROM salle sa JOIN seance se ON se.id_salle = sa.id
GROUP BY sa.id, sa.nom;

-- Q10. Salles ayant plus de 3 séances (HAVING)
SELECT sa.nom AS salle, COUNT(se.id) AS nb_seances
FROM salle sa JOIN seance se ON se.id_salle = sa.id
GROUP BY sa.id, sa.nom
HAVING COUNT(se.id) > 3;

-- ========== NIVEAU 3 : JOINTURES ==========

-- Q11. Films et leur réalisateur (INNER JOIN)
SELECT f.titre, CONCAT(r.prenom, ' ', r.nom) AS realisateur
FROM film f INNER JOIN realisateur r ON r.id = f.id_realisateur;

-- Q12. Films et leurs genres regroupés (GROUP_CONCAT, spécifique MySQL/MariaDB)
SELECT f.titre, GROUP_CONCAT(g.libelle ORDER BY g.libelle SEPARATOR ', ') AS genres
FROM film f
JOIN film_genre fg ON fg.id_film = f.id
JOIN genre g ON g.id = fg.id_genre
GROUP BY f.id, f.titre;

-- Q13. Le programme complet : séance, film, salle
SELECT se.date_heure_debut, f.titre, sa.nom AS salle, se.version, se.prix_base
FROM seance se
JOIN film f ON f.id = se.id_film
JOIN salle sa ON sa.id = se.id_salle
ORDER BY se.date_heure_debut;

-- Q14. Tous les films, même sans séance (LEFT JOIN)
SELECT f.titre, COUNT(se.id) AS nb_seances
FROM film f LEFT JOIN seance se ON se.id_film = f.id
GROUP BY f.id, f.titre
ORDER BY nb_seances;

-- Q15. Clients n'ayant jamais réservé (LEFT JOIN + IS NULL)
SELECT p.prenom, p.nom
FROM client c
JOIN personne p ON p.id = c.id
LEFT JOIN reservation r ON r.id_client = c.id
WHERE r.id IS NULL;

-- Q16. Détail complet de la réservation n°9 (6 tables jointes)
SELECT r.id AS reservation, CONCAT(p.prenom, ' ', p.nom) AS client, f.titre,
       se.date_heure_debut, sa.nom AS salle, CONCAT(si.rangee, si.numero) AS siege,
       pr.tarif, pr.prix
FROM reservation r
JOIN personne p ON p.id = r.id_client
JOIN seance se ON se.id = r.id_seance
JOIN film f ON f.id = se.id_film
JOIN salle sa ON sa.id = se.id_salle
JOIN place_reservee pr ON pr.id_reservation = r.id
JOIN siege si ON si.id = pr.id_siege
WHERE r.id = 9;

-- Q17. Tous les employés et leur équipe, même sans équipe (RIGHT JOIN)
SELECT e.poste, eq.nom AS equipe
FROM equipe eq RIGHT JOIN employe e ON e.id_equipe = eq.id;

-- ========== NIVEAU 4 : SOUS-REQUÊTES ==========

-- Q18. Séances plus chères que la moyenne
SELECT f.titre, se.date_heure_debut, se.prix_base
FROM seance se JOIN film f ON f.id = se.id_film
WHERE se.prix_base > (SELECT AVG(prix_base) FROM seance);

-- Q19. Films n'ayant jamais été réservés (NOT IN)
SELECT titre FROM film
WHERE id NOT IN (SELECT se.id_film FROM seance se JOIN reservation r ON r.id_seance = se.id);

-- Q20. Panier moyen des réservations confirmées (sous-requête dans FROM)
SELECT ROUND(AVG(t.total), 2) AS panier_moyen
FROM (
  SELECT pr.id_reservation, SUM(pr.prix) AS total
  FROM place_reservee pr JOIN reservation r ON r.id = pr.id_reservation
  WHERE r.statut = 'confirmée'
  GROUP BY pr.id_reservation
) AS t;

-- ========== NIVEAU 5 : INDICATEURS MÉTIER (Data Analyst) ==========

-- Q21. Chiffre d'affaires par mois
SELECT DATE_FORMAT(date_paiement, '%Y-%m') AS mois,
       SUM(montant) AS chiffre_affaires, COUNT(*) AS nb_paiements
FROM paiement
WHERE statut = 'accepté'
GROUP BY mois
ORDER BY mois;

-- Q22. Top 5 des films par places vendues
SELECT f.titre, COUNT(*) AS places_vendues, SUM(pr.prix) AS chiffre_affaires
FROM place_reservee pr
JOIN reservation r ON r.id = pr.id_reservation
JOIN seance se ON se.id = pr.id_seance
JOIN film f ON f.id = se.id_film
WHERE r.statut = 'confirmée'
GROUP BY f.id, f.titre
ORDER BY places_vendues DESC
LIMIT 5;

-- Q23. Taux de remplissage de chaque séance (l'attribut dérivé /tauxRemplissage)
SELECT se.id AS seance, f.titre, sa.nom AS salle, sa.capacite,
       COUNT(r.id) AS places_vendues,
       ROUND(COUNT(r.id) / sa.capacite * 100, 2) AS taux_remplissage_pct
FROM seance se
JOIN film f ON f.id = se.id_film
JOIN salle sa ON sa.id = se.id_salle
LEFT JOIN place_reservee pr ON pr.id_seance = se.id
LEFT JOIN reservation r ON r.id = pr.id_reservation AND r.statut = 'confirmée'
GROUP BY se.id, f.titre, sa.nom, sa.capacite
ORDER BY taux_remplissage_pct DESC;

-- Q24. Répartition du chiffre d'affaires par moyen de paiement
SELECT moyen, COUNT(*) AS nb_paiements, SUM(montant) AS total
FROM paiement WHERE statut = 'accepté'
GROUP BY moyen;

-- Q25. Segmentation des clients (CASE)
SELECT p.prenom, p.nom, COUNT(r.id) AS nb_reservations,
       CASE
         WHEN COUNT(r.id) = 0 THEN 'Inactif'
         WHEN COUNT(r.id) = 1 THEN 'Nouveau client'
         WHEN COUNT(r.id) >= 3 THEN 'Client fidèle'
         ELSE 'Client régulier'
       END AS segment
FROM client c
JOIN personne p ON p.id = c.id
LEFT JOIN reservation r ON r.id_client = c.id AND r.statut = 'confirmée'
GROUP BY c.id, p.prenom, p.nom
ORDER BY nb_reservations DESC;

-- Q26. Répartition des tarifs en pourcentage
SELECT pr.tarif, COUNT(*) AS nb_places,
       ROUND(COUNT(*) * 100 / (SELECT COUNT(*) FROM place_reservee pr2
                               JOIN reservation r2 ON r2.id = pr2.id_reservation
                               WHERE r2.statut = 'confirmée'), 1) AS pourcentage
FROM place_reservee pr
JOIN reservation r ON r.id = pr.id_reservation
WHERE r.statut = 'confirmée'
GROUP BY pr.tarif;

-- ========== À TOI DE JOUER (solutions plus tard) ==========
-- E1. Quel est le film le mieux noté (moyenne des avis) ?
-- E2. Combien de places au tarif 'enfant' ont été vendues (réservations confirmées) ?
-- E3. Quel client a dépensé le plus (somme de ses paiements acceptés) ?
