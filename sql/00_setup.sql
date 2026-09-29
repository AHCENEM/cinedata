-- 00_setup.sql : création de la base et de l'utilisateur dédié (à exécuter en root)
CREATE DATABASE cinedata CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'cinedata_dev'@'localhost' IDENTIFIED BY 'A_REMPLACER';
GRANT ALL PRIVILEGES ON cinedata.* TO 'cinedata_dev'@'localhost';
SHOW GRANTS FOR 'cinedata_dev'@'localhost';