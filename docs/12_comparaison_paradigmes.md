# CinéData - Comparaison des paradigmes de bases de données

Ce document compare les quatre modèles pratiqués dans le projet CinéData, à partir des résultats obtenus pendant les phases 5 à 10.

| Modèle | SGBD utilisé | Dossier du projet |
|---|---|---|
| Relationnel | MariaDB 10.4 | `sql/` |
| Objet-relationnel | PostgreSQL 18 | `pg/` |
| Objet (pur) | non installé : notion théorique du cours | - |
| Document (NoSQL) | MongoDB 9 | `mongo/` |

---

## 1. Tableau comparatif

| Critère | Relationnel (MariaDB) | Objet-relationnel (PostgreSQL) | Objet pur (OODBMS) | Document (MongoDB) |
|---|---|---|---|---|
| Unité de stockage | ligne d'une table | ligne, pouvant contenir des objets | objet | document JSON (BSON) |
| Schéma | fixe (`CREATE TABLE`) | fixe, enrichi de types | défini par les classes | flexible, validation optionnelle |
| Relations | clés étrangères et jointures | clés étrangères, héritage natif | références entre objets | imbrication ou références manuelles |
| Héritage | simulé (3 stratégies) | natif (`INHERITS`) | natif | aucun (champ « type ») |
| Types complexes | non (atomiques, 1FN) | types composés, ENUM, tableaux, JSONB | oui | sous-documents et tableaux |
| Intégrité | très forte (PK, FK, CHECK, UNIQUE) | forte, avec des limites dans l'héritage | dépend du système | faible par défaut |
| Transactions | ACID complètes | ACID complètes | variables | ACID possibles, pensées pour un document |
| Langage | SQL standard | SQL étendu, PL/pgSQL | langage objet (OQL) | API JavaScript, pipeline d'agrégation |
| Montée en charge | verticale surtout | verticale surtout | variable | horizontale (sharding) |
| Cas d'usage typique | gestion, finance, réservations | données métier riches, SIG, analytique | CAO, systèmes embarqués | contenus, catalogues, journaux, IoT |

---

## 2. Ce que le projet a démontré

### 2.1 Le relationnel garantit l'intégrité
- Les contraintes ont refusé toutes les données incohérentes : 11 tests sur 11 réussis (`sql/09_resultats.txt`).
- La règle R1 (un siège réservé une seule fois par séance) est garantie par la base elle-même, grâce à `UNIQUE(id_seance, id_siege)`.
- La procédure `reserver_place` assure l'atomicité : en cas d'échec, `ROLLBACK`, et aucune réservation à moitié créée.
- Le coût : il faut normaliser (phase 3) et écrire des jointures, jusqu'à 6 tables pour le détail d'une réservation.

### 2.2 L'objet-relationnel rapproche la base du modèle objet
- L'héritage UML Personne → Client / Employé est natif : `SELECT * FROM personne` renvoie aussi les clients et les employés.
- Une adresse est un seul champ structuré (`adresse_t`), et les tags d'un film un tableau, sans table de jonction.
- Les fonctions se comportent comme des méthodes : `p.age_annees`.
- **La limite observée (test 2e)** : `UNIQUE` et `PRIMARY KEY` ne s'appliquent qu'à chaque table fille séparément. Un même e-mail a été accepté dans `client` ET dans `employe`. Sous MariaDB (stratégie « une table par classe avec jointures »), c'était impossible.

### 2.3 Le document offre la souplesse
- 7 avis, 7 structures différentes : un avis avec des réponses imbriquées, un sans commentaire, un avec un drapeau `spoiler`, un avec un contexte de visite.
- Un nouveau champ (`modere`) s'ajoute à un seul document, sans `ALTER TABLE`.
- Les journaux de navigation ont des champs différents selon le type d'événement.
- Le pipeline d'agrégation produit les mêmes indicateurs que SQL : note moyenne, tags populaires, entonnoir de conversion.
- Le coût : sans validation `$jsonSchema`, n'importe quelle donnée est acceptée, et les jointures sont peu naturelles.

### 2.4 Un point commun : les index
| SGBD | Sans index | Avec index |
|---|---|---|
| MariaDB (`EXPLAIN`) | `type = ALL`, environ 600 lignes lues | `type = ref`, quelques lignes |
| MongoDB (`explain`) | `COLLSCAN`, 7 documents examinés | `IXSCAN`, 2 documents examinés |

Le principe est identique d'un paradigme à l'autre : un index évite de parcourir toutes les données.

---

## 3. Les choix faits pour CinéData (architecture polyglotte)

| Données | Modèle retenu | Justification |
|---|---|---|
| Réservations, places, paiements, tickets | **Relationnel** | argent et sièges : intégrité stricte, transactions ACID, règles R1, R2, R3 garanties par la base |
| Clients, employés, salles, séances, films | **Relationnel** | données structurées et reliées ; e-mail unique sur toutes les personnes (R10) |
| Statistiques et tableaux de bord | **Relationnel** (vues) | calculées à la volée à partir des données de référence, jamais dupliquées |
| Avis clients | **Document** | structure variable, réponses imbriquées, champs optionnels, peu de relations |
| Journaux de navigation | **Document** | gros volumes, structure différente par événement, pas de relations, écritures rapides |
| Hiérarchies et types riches (adresse, tags) | **Objet-relationnel** (option) | si l'on choisit PostgreSQL : moins de tables, mais attention à l'unicité dans l'héritage |

**Conclusion :** aucun modèle n'est « le meilleur ». Le bon choix dépend des données :
- **besoin d'intégrité et de transactions** → relationnel ;
- **structure riche, proche des objets métier** → objet-relationnel ;
- **structure variable, gros volumes, peu de relations** → document.

Un même système peut combiner plusieurs SGBD : c'est la **persistance polyglotte**.

---

## 4. Les critères de choix (grille de décision)

1. Les données ont-elles une structure stable et des relations fortes ? → relationnel.
2. Faut-il des transactions sur plusieurs entités (argent, stock, places) ? → relationnel.
3. Les objets métier sont-ils complexes (types imbriqués, héritage) ? → objet-relationnel.
4. La structure varie-t-elle d'un enregistrement à l'autre ? → document.
5. Le volume est-il très élevé, avec surtout des écritures simples ? → document.
6. L'équipe maîtrise-t-elle déjà SQL ? → un argument concret pour rester en relationnel.
