\# CinéData - Passage UML → relationnel



\## 1. Les règles appliquées



| Élément UML | Règle | Exemple CinéData |

|---|---|---|

| Classe | une classe = une table, un attribut = une colonne | Film → table `film` |

| Identifiant | une clé primaire par table ; id technique auto-incrémenté | `film.id` |

| Association 1 -- \* | clé étrangère \*\*côté \\\*\*\* | `seance.id\_film` → `film.id` |

| Association 1 -- 0..1 | clé étrangère côté dépendant + \*\*UNIQUE\*\* | `carte\_fidelite.id\_client` UNIQUE |

| Association \* -- \* | \*\*table de jonction\*\*, clé primaire composée | `film\_genre(id\_film, id\_genre)` |

| Classe d'association | table de jonction \*\*+ ses attributs\*\* | `casting(id\_film, id\_acteur, role)` |

| Association réflexive | clé étrangère vers \*\*la même table\*\* | `employe.id\_responsable` → `employe.id` |

| Composition ◆ | clé étrangère \*\*ON DELETE CASCADE\*\* | `siege.id\_salle` (R9) |

| Agrégation ◇ | clé étrangère \*\*nullable\*\*, ON DELETE SET NULL | `employe.id\_equipe` |



\## 2. L'héritage Personne → Client / Employe : 3 stratégies comparées



| Stratégie | Tables obtenues | Avantages | Inconvénients |

|---|---|---|---|

| A. Une table par hiérarchie | `personne` avec toutes les colonnes + `type` (discriminateur) | aucune jointure | beaucoup de NULL (salaire vide pour un client), contraintes NOT NULL impossibles |

| B. Une table par classe concrète | `client` et `employe`, chacune avec nom, prénom, e-mail… | simple | colonnes dupliquées, e-mail unique difficile à garantir sur les deux tables |

| C. Une table par classe avec jointures | `personne` + `client(id → personne.id)` + `employe(id → personne.id)` | normalisé, aucune duplication | jointure nécessaire pour reconstituer un client |



\*\*Choix : stratégie C\*\*, recommandée par le cours pour la normalisation. L'e-mail est UNIQUE à un seul endroit, et chaque table a ses propres NOT NULL.



\## 3. L'interface MoyenPaiement → PaiementCB / PaiementEspeces



Ici, on choisit volontairement la \*\*stratégie A (table unique)\*\* : les deux sous-types ne diffèrent que d'une colonne chacun.

→ une seule table `paiement` avec une colonne discriminatrice `moyen` ('CB' ou 'ESPECES'), plus `numero\_transaction` et `montant\_recu`, qui peuvent être NULL.



\## 4. Ce qui disparaît



| Élément UML | Devenir |

|---|---|

| Méthodes (`reserver()`, `annuler()`, `imprimer()`) | code applicatif (PHP) ou procédures stockées |

| Attributs dérivés (`/age`, `/tauxRemplissage`, `/montantTotal`) | \*\*calculés\*\* par des requêtes ou des vues, jamais stockés |

| Constantes (`CAPACITE\_MAX`, `MAX\_PLACES`) | contraintes \*\*CHECK\*\* ou règles applicatives |

| Attribut de classe (`nbTotalBillets`) | requête `COUNT(\*)` |

| Classe `Imprimante` (simple dépendance) | aucune table : rien à stocker |



\## 5. Le schéma relationnel



Notation : \*\*PK\*\* = clé primaire, \*\*#\*\* = clé étrangère.



\*\*Personnes\*\*

\- personne (\*\*id\*\*, nom, prenom, date\_naissance, email UNIQUE, telephone)

\- client (\*\*#id\*\* → personne, adresse, date\_inscription)

\- equipe (\*\*id\*\*, nom)

\- employe (\*\*#id\*\* → personne, date\_embauche, poste, salaire, #id\_responsable → employe NULL, #id\_equipe → equipe NULL)

\- carte\_fidelite (\*\*id\*\*, numero UNIQUE, points DEFAULT 0, date\_creation, #id\_client → client UNIQUE)



\*\*Catalogue\*\*

\- realisateur (\*\*id\*\*, nom, prenom)

\- acteur (\*\*id\*\*, nom, prenom)

\- genre (\*\*id\*\*, libelle UNIQUE)

\- film (\*\*id\*\*, titre, duree, date\_sortie, classification, synopsis, #id\_realisateur → realisateur)

\- film\_genre (\*\*#id\_film, #id\_genre\*\*)

\- casting (\*\*#id\_film, #id\_acteur\*\*, role)

\- avis (\*\*id\*\*, note CHECK 1-5, commentaire, date\_avis, #id\_client, #id\_film), UNIQUE(id\_client, id\_film)



\*\*Programmation\*\*

\- salle (\*\*id\*\*, numero UNIQUE, nom, capacite CHECK 20-400, type)

\- siege (\*\*id\*\*, #id\_salle → salle ON DELETE CASCADE, rangee, numero, est\_pmr DEFAULT FALSE), UNIQUE(id\_salle, rangee, numero)

\- seance (\*\*id\*\*, date\_heure\_debut, version, prix\_base CHECK ≥ 0, #id\_film → film ON DELETE RESTRICT, #id\_salle → salle)



\*\*Billetterie\*\*

\- reservation (\*\*id\*\*, date\_reservation, statut DEFAULT 'en attente', #id\_client, #id\_seance)

\- place\_reservee (\*\*#id\_reservation, #id\_siege\*\*, #id\_seance, tarif, prix), \*\*UNIQUE(id\_seance, id\_siege)\*\*

\- paiement (\*\*id\*\*, montant, date\_paiement, statut, moyen, numero\_transaction NULL, montant\_recu NULL, #id\_reservation UNIQUE)

\- ticket (\*\*id\*\*, code UNIQUE, date\_emission, #id\_reservation → reservation UNIQUE ON DELETE CASCADE)



\*\*Total : 19 tables.\*\*



\## 6. Correspondance des types (UML → MariaDB)



| UML | MariaDB |

|---|---|

| Integer | INT |

| String | VARCHAR(n) ou TEXT |

| Decimal (prix) | DECIMAL(6,2) |

| Boolean | BOOLEAN (= TINYINT(1)) |

| Date | DATE |

| DateTime | DATETIME |



\## 7. Une dénormalisation volontaire : la règle R1



R1 : \*un siège ne peut être réservé qu'une seule fois pour une même séance\*.

`place\_reservee` ne connaît que la réservation et le siège. Or la séance est dans `reservation`, et un UNIQUE ne peut pas porter sur deux tables.

\*\*Solution :\*\* on recopie `id\_seance` dans `place\_reservee` et on pose \*\*UNIQUE(id\_seance, id\_siege)\*\*. La base elle-même refusera la double réservation.

Le cours l'autorise : \*une légère dénormalisation est acceptable si elle sert une contrainte ou une performance critique\*.

