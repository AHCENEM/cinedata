-- =========================================================
-- CinéData - 01_create.sql : création des 19 tables (DDL)
-- SGBD : MariaDB 10.4
-- =========================================================
SET NAMES utf8mb4;
USE cinedata;

-- Suppression des tables pour pouvoir relancer le script
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS ticket, paiement, place_reservee, reservation, seance,
  siege, salle, avis, casting, film_genre, film, genre, acteur, realisateur,
  carte_fidelite, employe, equipe, client, personne;
SET FOREIGN_KEY_CHECKS = 1;

-- ===================== PERSONNES =====================

-- Héritage, stratégie "une table par classe avec jointures"
CREATE TABLE personne (
  id INT AUTO_INCREMENT,
  nom VARCHAR(50) NOT NULL,
  prenom VARCHAR(50) NOT NULL,
  date_naissance DATE,
  email VARCHAR(100) NOT NULL,
  telephone VARCHAR(20),
  CONSTRAINT pk_personne PRIMARY KEY (id),
  CONSTRAINT uq_personne_email UNIQUE (email)          -- R10
);

CREATE TABLE client (
  id INT,
  adresse VARCHAR(255),
  date_inscription DATE NOT NULL DEFAULT (CURRENT_DATE),
  CONSTRAINT pk_client PRIMARY KEY (id),
  CONSTRAINT fk_client_personne FOREIGN KEY (id)
    REFERENCES personne(id) ON DELETE CASCADE
);

CREATE TABLE equipe (
  id INT AUTO_INCREMENT,
  nom VARCHAR(50) NOT NULL,
  CONSTRAINT pk_equipe PRIMARY KEY (id)
);

CREATE TABLE employe (
  id INT,
  date_embauche DATE NOT NULL,
  poste VARCHAR(50) NOT NULL,
  salaire DECIMAL(8,2),
  id_responsable INT NULL,                             -- association réflexive
  id_equipe INT NULL,                                  -- agrégation
  CONSTRAINT pk_employe PRIMARY KEY (id),
  CONSTRAINT fk_employe_personne FOREIGN KEY (id)
    REFERENCES personne(id) ON DELETE CASCADE,
  CONSTRAINT fk_employe_responsable FOREIGN KEY (id_responsable)
    REFERENCES employe(id) ON DELETE SET NULL,
  CONSTRAINT fk_employe_equipe FOREIGN KEY (id_equipe)
    REFERENCES equipe(id) ON DELETE SET NULL,
  CONSTRAINT chk_employe_salaire CHECK (salaire >= 0)
);

CREATE TABLE carte_fidelite (
  id INT AUTO_INCREMENT,
  numero VARCHAR(20) NOT NULL,
  points INT NOT NULL DEFAULT 0,
  date_creation DATE NOT NULL DEFAULT (CURRENT_DATE),
  id_client INT NOT NULL,
  CONSTRAINT pk_carte PRIMARY KEY (id),
  CONSTRAINT uq_carte_numero UNIQUE (numero),
  CONSTRAINT uq_carte_client UNIQUE (id_client),       -- 1 carte max par client
  CONSTRAINT fk_carte_client FOREIGN KEY (id_client)
    REFERENCES client(id) ON DELETE CASCADE,
  CONSTRAINT chk_carte_points CHECK (points >= 0)
);

-- ===================== CATALOGUE =====================

CREATE TABLE realisateur (
  id INT AUTO_INCREMENT,
  nom VARCHAR(50) NOT NULL,
  prenom VARCHAR(50),
  CONSTRAINT pk_realisateur PRIMARY KEY (id)
);

CREATE TABLE acteur (
  id INT AUTO_INCREMENT,
  nom VARCHAR(50) NOT NULL,
  prenom VARCHAR(50),
  CONSTRAINT pk_acteur PRIMARY KEY (id)
);

CREATE TABLE genre (
  id INT AUTO_INCREMENT,
  libelle VARCHAR(50) NOT NULL,
  CONSTRAINT pk_genre PRIMARY KEY (id),
  CONSTRAINT uq_genre_libelle UNIQUE (libelle)
);

CREATE TABLE film (
  id INT AUTO_INCREMENT,
  titre VARCHAR(150) NOT NULL,
  duree INT NOT NULL,                                  -- en minutes
  date_sortie DATE,
  classification VARCHAR(15) NOT NULL DEFAULT 'Tous publics',
  synopsis TEXT,
  id_realisateur INT NOT NULL,
  CONSTRAINT pk_film PRIMARY KEY (id),
  CONSTRAINT fk_film_realisateur FOREIGN KEY (id_realisateur)
    REFERENCES realisateur(id) ON DELETE RESTRICT,
  CONSTRAINT chk_film_duree CHECK (duree > 0),
  CONSTRAINT chk_film_classif CHECK (classification IN ('Tous publics', '-12', '-16', '-18'))
);

-- Association N:M -> table de jonction
CREATE TABLE film_genre (
  id_film INT,
  id_genre INT,
  CONSTRAINT pk_film_genre PRIMARY KEY (id_film, id_genre),
  CONSTRAINT fk_fg_film FOREIGN KEY (id_film) REFERENCES film(id) ON DELETE CASCADE,
  CONSTRAINT fk_fg_genre FOREIGN KEY (id_genre) REFERENCES genre(id) ON DELETE CASCADE
);

-- Classe d'association -> table de jonction + attribut
CREATE TABLE casting (
  id_film INT,
  id_acteur INT,
  role VARCHAR(100),
  CONSTRAINT pk_casting PRIMARY KEY (id_film, id_acteur),
  CONSTRAINT fk_casting_film FOREIGN KEY (id_film) REFERENCES film(id) ON DELETE CASCADE,
  CONSTRAINT fk_casting_acteur FOREIGN KEY (id_acteur) REFERENCES acteur(id) ON DELETE CASCADE
);

CREATE TABLE avis (
  id INT AUTO_INCREMENT,
  note INT NOT NULL,
  commentaire TEXT,
  date_avis DATE NOT NULL DEFAULT (CURRENT_DATE),
  id_client INT NOT NULL,
  id_film INT NOT NULL,
  CONSTRAINT pk_avis PRIMARY KEY (id),
  CONSTRAINT uq_avis_client_film UNIQUE (id_client, id_film),  -- 1 avis par film et par client
  CONSTRAINT fk_avis_client FOREIGN KEY (id_client) REFERENCES client(id) ON DELETE CASCADE,
  CONSTRAINT fk_avis_film FOREIGN KEY (id_film) REFERENCES film(id) ON DELETE CASCADE,
  CONSTRAINT chk_avis_note CHECK (note BETWEEN 1 AND 5)
);

-- ===================== PROGRAMMATION =====================

CREATE TABLE salle (
  id INT AUTO_INCREMENT,
  numero INT NOT NULL,
  nom VARCHAR(50) NOT NULL,
  capacite INT NOT NULL,
  type VARCHAR(10) NOT NULL DEFAULT 'standard',
  CONSTRAINT pk_salle PRIMARY KEY (id),
  CONSTRAINT uq_salle_numero UNIQUE (numero),
  CONSTRAINT chk_salle_capacite CHECK (capacite BETWEEN 20 AND 400),   -- R4
  CONSTRAINT chk_salle_type CHECK (type IN ('standard', '3D', 'IMAX'))
);

-- Composition Salle <>-- Siege -> ON DELETE CASCADE (R9)
CREATE TABLE siege (
  id INT AUTO_INCREMENT,
  id_salle INT NOT NULL,
  rangee CHAR(2) NOT NULL,
  numero INT NOT NULL,
  est_pmr BOOLEAN NOT NULL DEFAULT FALSE,
  CONSTRAINT pk_siege PRIMARY KEY (id),
  CONSTRAINT uq_siege_position UNIQUE (id_salle, rangee, numero),
  CONSTRAINT fk_siege_salle FOREIGN KEY (id_salle) REFERENCES salle(id) ON DELETE CASCADE
);

CREATE TABLE seance (
  id INT AUTO_INCREMENT,
  date_heure_debut DATETIME NOT NULL,
  version VARCHAR(10) NOT NULL DEFAULT 'VF',
  prix_base DECIMAL(6,2) NOT NULL,
  id_film INT NOT NULL,
  id_salle INT NOT NULL,
  CONSTRAINT pk_seance PRIMARY KEY (id),
  CONSTRAINT fk_seance_film FOREIGN KEY (id_film)
    REFERENCES film(id) ON DELETE RESTRICT,                         -- R8
  CONSTRAINT fk_seance_salle FOREIGN KEY (id_salle)
    REFERENCES salle(id) ON DELETE RESTRICT,
  CONSTRAINT chk_seance_prix CHECK (prix_base >= 0),                 -- R5
  CONSTRAINT chk_seance_version CHECK (version IN ('VF', 'VOSTFR'))
);

-- ===================== BILLETTERIE =====================

CREATE TABLE reservation (
  id INT AUTO_INCREMENT,
  date_reservation DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  statut VARCHAR(15) NOT NULL DEFAULT 'en attente',
  id_client INT NOT NULL,
  id_seance INT NOT NULL,
  CONSTRAINT pk_reservation PRIMARY KEY (id),
  CONSTRAINT fk_resa_client FOREIGN KEY (id_client) REFERENCES client(id) ON DELETE RESTRICT,
  CONSTRAINT fk_resa_seance FOREIGN KEY (id_seance) REFERENCES seance(id) ON DELETE RESTRICT,
  CONSTRAINT chk_resa_statut CHECK (statut IN ('en attente', 'confirmée', 'annulée'))
);

-- Classe d'association Reservation -- Siege
CREATE TABLE place_reservee (
  id_reservation INT,
  id_siege INT,
  id_seance INT NOT NULL,                       -- dénormalisation volontaire pour R1
  tarif VARCHAR(10) NOT NULL DEFAULT 'plein',
  prix DECIMAL(6,2) NOT NULL,
  CONSTRAINT pk_place PRIMARY KEY (id_reservation, id_siege),
  CONSTRAINT uq_place_seance_siege UNIQUE (id_seance, id_siege),    -- R1
  CONSTRAINT fk_place_resa FOREIGN KEY (id_reservation) REFERENCES reservation(id) ON DELETE CASCADE,
  CONSTRAINT fk_place_siege FOREIGN KEY (id_siege) REFERENCES siege(id) ON DELETE RESTRICT,
  CONSTRAINT fk_place_seance FOREIGN KEY (id_seance) REFERENCES seance(id) ON DELETE RESTRICT,
  CONSTRAINT chk_place_tarif CHECK (tarif IN ('plein', 'reduit', 'enfant')),
  CONSTRAINT chk_place_prix CHECK (prix >= 0)
);

-- Interface MoyenPaiement -> table unique avec discriminateur "moyen"
CREATE TABLE paiement (
  id INT AUTO_INCREMENT,
  montant DECIMAL(6,2) NOT NULL,
  date_paiement DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  statut VARCHAR(15) NOT NULL,
  moyen VARCHAR(10) NOT NULL,
  numero_transaction VARCHAR(50) NULL,
  montant_recu DECIMAL(6,2) NULL,
  id_reservation INT NOT NULL,
  CONSTRAINT pk_paiement PRIMARY KEY (id),
  CONSTRAINT uq_paiement_resa UNIQUE (id_reservation),
  CONSTRAINT fk_paiement_resa FOREIGN KEY (id_reservation)
    REFERENCES reservation(id) ON DELETE RESTRICT,     -- on garde l'historique financier
  CONSTRAINT chk_paiement_montant CHECK (montant >= 0),
  CONSTRAINT chk_paiement_statut CHECK (statut IN ('accepté', 'refusé')),
  CONSTRAINT chk_paiement_moyen CHECK (moyen IN ('CB', 'ESPECES')),
  CONSTRAINT chk_paiement_cb CHECK (moyen <> 'CB' OR numero_transaction IS NOT NULL)
);

-- Composition Reservation <>-- Ticket
CREATE TABLE ticket (
  id INT AUTO_INCREMENT,
  code VARCHAR(20) NOT NULL,
  date_emission DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  id_reservation INT NOT NULL,
  CONSTRAINT pk_ticket PRIMARY KEY (id),
  CONSTRAINT uq_ticket_code UNIQUE (code),
  CONSTRAINT uq_ticket_resa UNIQUE (id_reservation),
  CONSTRAINT fk_ticket_resa FOREIGN KEY (id_reservation)
    REFERENCES reservation(id) ON DELETE CASCADE
);

SHOW TABLES;