\# CinéData - Cahier des charges



\## 1. Contexte

Le cinéma « Le Grand Écran » (6 salles) gère aujourd'hui sa programmation et sa billetterie

avec des tableurs. Il veut une base de données centralisée pour la programmation,

les réservations en ligne et au guichet, le personnel et les statistiques.



\## 2. Acteurs

\- Client : consulte le programme, réserve et paie en ligne, gère son compte et sa carte fidélité, laisse un avis.

\- Caissier : vend des billets au guichet, encaisse, imprime les tickets.

\- Projectionniste : consulte le planning des séances de ses salles.

\- Manager : gère le catalogue de films, programme les séances, gère le personnel, consulte les statistiques.

\- Système de paiement (externe) : valide ou refuse les paiements par carte.



\## 3. Besoins fonctionnels

\### Catalogue

\- Enregistrer les films : titre, durée, date de sortie, classification (Tous publics, -12, -16, -18), synopsis.

\- Un film a un ou plusieurs genres ; un genre regroupe plusieurs films.

\- Un film a un réalisateur et des acteurs (avec le nom du rôle joué).



\### Salles et programmation

\- Chaque salle a un numéro, un nom, une capacité et un type (standard, 3D, IMAX).

\- Une salle est composée de sièges (rangée + numéro), certains réservés PMR.

\- Une séance = un film, une salle, une date/heure de début, une version (VF/VOSTFR), un prix de base.



\### Billetterie

\- Un client (ou un caissier pour un client au guichet) réserve une ou plusieurs places pour une séance.

\- Chaque place réservée correspond à un siège précis et à un tarif (plein, réduit, enfant).

\- Une réservation est payée par carte bancaire ou en espèces (espèces uniquement au guichet).

\- Un ticket est généré et peut être imprimé.



\### Clients et fidélité

\- Client : nom, prénom, date de naissance, e-mail, téléphone, adresse.

\- Un client peut posséder au maximum une carte fidélité (numéro, points, date de création).

\- Un client peut laisser des avis (note de 1 à 5 + commentaire) sur les films vus.



\### Personnel

\- Employé : nom, prénom, date de naissance, date d'embauche, poste, salaire.

\- Un employé peut avoir un responsable (lui-même employé). Les employés sont organisés en équipes.



\### Statistiques (manager)

\- Chiffre d'affaires par jour, mois, film et salle.

\- Taux de remplissage des séances et des salles.

\- Films les plus vus, clients les plus fidèles, films souvent vus par les mêmes clients.



\## 4. Règles métier

\- R1 : un siège ne peut être réservé qu'une seule fois pour une même séance.

\- R2 : une réservation contient entre 1 et 10 places.

\- R3 : deux séances ne peuvent pas se chevaucher dans la même salle (durée du film + 30 min de ménage).

\- R4 : la capacité d'une salle est comprise entre 20 et 400 places.

\- R5 : les prix sont positifs ; le tarif réduit (carte fidélité) = -20 % sur le prix de base.

\- R6 : un client doit avoir l'âge requis par la classification du film.

\- R7 : une réservation peut être annulée jusqu'à 1 heure avant le début de la séance.

\- R8 : un film ayant des séances ne peut pas être supprimé du catalogue.

\- R9 : si une salle est supprimée, ses sièges le sont aussi.

\- R10 : l'e-mail d'un client est unique.



\## 5. Contraintes de sécurité

\- Chaque rôle n'accède qu'aux données nécessaires (moindre privilège).

\- Les données personnelles des clients (e-mail, téléphone) sont masquées pour les analystes.

\- Les mots de passe ne sont jamais stockés en clair.

