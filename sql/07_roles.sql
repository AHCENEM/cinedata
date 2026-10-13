-- =========================================================
-- CinéData - 07_roles.sql : rôles et droits (DCL)
-- À EXÉCUTER EN ROOT (création de rôles et d'utilisateurs)
-- =========================================================
SET NAMES utf8mb4;

-- ---------------------------------------------------------
-- 0. Nettoyage (permet de relancer le script)
-- ---------------------------------------------------------
DROP USER IF EXISTS 'caisse_yasmine'@'localhost', 'manager_helene'@'localhost', 'analyste_data'@'localhost';
DROP ROLE IF EXISTS role_caissier, role_manager, role_analyste;

-- ---------------------------------------------------------
-- 1. Création des 3 rôles
-- ---------------------------------------------------------
CREATE ROLE role_caissier;
CREATE ROLE role_manager;
CREATE ROLE role_analyste;

-- ---------------------------------------------------------
-- 2. Droits du rôle CAISSIER
--    Lecture du programme + réservation UNIQUEMENT via la procédure
-- ---------------------------------------------------------
GRANT SELECT ON cinedata.film        TO role_caissier;
GRANT SELECT ON cinedata.seance      TO role_caissier;
GRANT SELECT ON cinedata.salle       TO role_caissier;
GRANT SELECT, UPDATE ON cinedata.reservation TO role_caissier;   -- UPDATE sera retiré plus bas (REVOKE)
GRANT EXECUTE ON PROCEDURE cinedata.reserver_place TO role_caissier;

-- ---------------------------------------------------------
-- 3. Droits du rôle MANAGER
--    Gestion complète du contenu, mais pas de la structure
-- ---------------------------------------------------------
GRANT SELECT, INSERT, UPDATE, DELETE ON cinedata.* TO role_manager;
GRANT EXECUTE ON cinedata.* TO role_manager;

-- ---------------------------------------------------------
-- 4. Droits du rôle ANALYSTE
--    Lecture seule, et SANS la table personne (données personnelles)
-- ---------------------------------------------------------
GRANT SELECT ON cinedata.film           TO role_analyste;
GRANT SELECT ON cinedata.genre          TO role_analyste;
GRANT SELECT ON cinedata.film_genre     TO role_analyste;
GRANT SELECT ON cinedata.salle          TO role_analyste;
GRANT SELECT ON cinedata.seance         TO role_analyste;
GRANT SELECT ON cinedata.reservation    TO role_analyste;
GRANT SELECT ON cinedata.place_reservee TO role_analyste;
GRANT SELECT ON cinedata.paiement       TO role_analyste;
GRANT SELECT ON cinedata.avis           TO role_analyste;

-- ---------------------------------------------------------
-- 5. Création des utilisateurs
-- ---------------------------------------------------------
CREATE USER 'caisse_yasmine'@'localhost' IDENTIFIED BY 'Caisse_2026';
CREATE USER 'manager_helene'@'localhost' IDENTIFIED BY 'Manager_2026';
CREATE USER 'analyste_data'@'localhost'  IDENTIFIED BY 'Analyste_2026';

-- ---------------------------------------------------------
-- 6. Attribution des rôles aux utilisateurs
-- ---------------------------------------------------------
GRANT role_caissier TO 'caisse_yasmine'@'localhost';
GRANT role_manager  TO 'manager_helene'@'localhost';
GRANT role_analyste TO 'analyste_data'@'localhost';

-- Activer le rôle automatiquement à chaque connexion
SET DEFAULT ROLE role_caissier FOR 'caisse_yasmine'@'localhost';
SET DEFAULT ROLE role_manager  FOR 'manager_helene'@'localhost';
SET DEFAULT ROLE role_analyste FOR 'analyste_data'@'localhost';

-- ---------------------------------------------------------
-- 7. REVOKE : finalement, le caissier ne doit pas modifier
--    une réservation directement (il doit passer par la procédure)
-- ---------------------------------------------------------
REVOKE UPDATE ON cinedata.reservation FROM role_caissier;

-- ---------------------------------------------------------
-- 8. Vérifications
-- ---------------------------------------------------------
SHOW GRANTS FOR role_caissier;
SHOW GRANTS FOR role_manager;
SHOW GRANTS FOR role_analyste;
SHOW GRANTS FOR 'caisse_yasmine'@'localhost';

SELECT user, is_role, default_role
FROM mysql.user
WHERE user LIKE 'role_%' OR user IN ('caisse_yasmine', 'manager_helene', 'analyste_data');
