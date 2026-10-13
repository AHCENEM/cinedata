# CinéData - Normalisation

## 0. Le tableau de départ (export Excel de l'ancienne billetterie)

| num_resa | date_resa | client_nom | client_email | film_titre | film_genres | realisateur | seance_date | salle_num | salle_nom | salle_capacite | sieges | tarifs | montant_total |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1001 | 01/10/2026 | Karim Benali | karim@mail.fr | Dune 2 | SF, Aventure | D. Villeneuve | 03/10/2026 20:00 | 3 | Lumière | 180 | F12, F13 | plein, réduit | 21.60 |
| 1002 | 01/10/2026 | Julie Martin | julie@mail.fr | Dune 2 | SF, Aventure | D. Villeneuve | 03/10/2026 20:00 | 3 | Lumière | 180 | G5 | plein | 12.00 |
| 1003 | 02/10/2026 | Karim Benali | karim@mail.fr | Monte-Cristo | Aventure, Drame | A. de La Patellière | 04/10/2026 18:00 | 1 | Méliès | 120 | C3, C4, C5 | plein, enfant, enfant | 28.00 |

---

## 1. Première forme normale (1FN)

**Règle :** chaque cellule contient une seule valeur (atomique).

**Problème :** `film_genres`, `sieges` et `tarifs` contiennent plusieurs valeurs.
**Solution :** une ligne par place réservée, et les genres dans une table séparée.
`montant_total` est retiré : c'est une donnée **calculable**, la stocker crée un risque d'incohérence.

### PlaceReservee_1FN - clé (num_resa, siege)

| num_resa | siege | tarif | date_resa | client_nom | client_email | film_titre | realisateur | seance_date | salle_num | salle_nom | salle_capacite |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1001 | F12 | plein | 01/10/2026 | Karim Benali | karim@mail.fr | Dune 2 | D. Villeneuve | 03/10/2026 20:00 | 3 | Lumière | 180 |
| 1001 | F13 | réduit | 01/10/2026 | Karim Benali | karim@mail.fr | Dune 2 | D. Villeneuve | 03/10/2026 20:00 | 3 | Lumière | 180 |
| 1002 | G5 | plein | 01/10/2026 | Julie Martin | julie@mail.fr | Dune 2 | D. Villeneuve | 03/10/2026 20:00 | 3 | Lumière | 180 |
| 1003 | C3 | plein | 02/10/2026 | Karim Benali | karim@mail.fr | Monte-Cristo | A. de La Patellière | 04/10/2026 18:00 | 1 | Méliès | 120 |
| 1003 | C4 | enfant | 02/10/2026 | Karim Benali | karim@mail.fr | Monte-Cristo | A. de La Patellière | 04/10/2026 18:00 | 1 | Méliès | 120 |
| 1003 | C5 | enfant | 02/10/2026 | Karim Benali | karim@mail.fr | Monte-Cristo | A. de La Patellière | 04/10/2026 18:00 | 1 | Méliès | 120 |

### FilmGenre - clé (film_titre, genre)

| film_titre | genre |
|---|---|
| Dune 2 | SF |
| Dune 2 | Aventure |
| Monte-Cristo | Aventure |
| Monte-Cristo | Drame |

**Constat :** en 1FN, mais très redondante (l'e-mail de Karim apparaît 4 fois).

---

## 2. Deuxième forme normale (2FN)

**Règle :** être en 1FN, et chaque colonne non-clé dépend de **toute** la clé (pas d'une partie seulement).

**Analyse des dépendances** (la clé est composée : num_resa + siege) :

| Colonne | Dépend de | Verdict |
|---|---|---|
| tarif | num_resa **et** siege | OK : dépend de toute la clé |
| date_resa, client_nom, client_email, film_titre, realisateur, seance_date, salle_num, salle_nom, salle_capacite | **num_resa seul** | Dépendance **partielle** : à sortir |

**Solution :** on sépare ce qui dépend de la réservation entière.

### PlaceReservee - clé (num_resa, siege)

| num_resa | siege | tarif |
|---|---|---|
| 1001 | F12 | plein |
| 1001 | F13 | réduit |
| 1002 | G5 | plein |
| 1003 | C3 | plein |
| 1003 | C4 | enfant |
| 1003 | C5 | enfant |

### Reservation_2FN - clé (num_resa)

| num_resa | date_resa | client_nom | client_email | film_titre | realisateur | seance_date | salle_num | salle_nom | salle_capacite |
|---|---|---|---|---|---|---|---|---|---|
| 1001 | 01/10/2026 | Karim Benali | karim@mail.fr | Dune 2 | D. Villeneuve | 03/10/2026 20:00 | 3 | Lumière | 180 |
| 1002 | 01/10/2026 | Julie Martin | julie@mail.fr | Dune 2 | D. Villeneuve | 03/10/2026 20:00 | 3 | Lumière | 180 |
| 1003 | 02/10/2026 | Karim Benali | karim@mail.fr | Monte-Cristo | A. de La Patellière | 04/10/2026 18:00 | 1 | Méliès | 120 |

**Constat :** en 2FN, mais il reste des dépendances **en chaîne** (« Lumière / 180 » se répète à chaque réservation de la salle 3).

---

## 3. Troisième forme normale (3FN)

**Règle :** être en 2FN, et aucune colonne non-clé ne dépend d'une **autre colonne non-clé** (pas de dépendance transitive).

**Dépendances transitives trouvées dans Reservation_2FN :**

| Chaîne | Explication |
|---|---|
| num_resa → client_email → client_nom | le nom dépend du client, pas de la réservation |
| num_resa → salle_num → salle_nom, salle_capacite | la capacité dépend de la salle |
| num_resa → (salle_num, seance_date) → film_titre | le film dépend de la séance |
| film_titre → realisateur | le réalisateur dépend du film |

**Solution :** chaque « chose » a sa propre table.

### Client - clé (client_email)
| client_email | client_nom |
|---|---|
| karim@mail.fr | Karim Benali |
| julie@mail.fr | Julie Martin |

### Salle - clé (salle_num)
| salle_num | salle_nom | salle_capacite |
|---|---|---|
| 1 | Méliès | 120 |
| 3 | Lumière | 180 |

### Film - clé (film_titre)
| film_titre | realisateur |
|---|---|
| Dune 2 | D. Villeneuve |
| Monte-Cristo | A. de La Patellière |

### Seance - clé (salle_num, seance_date)
| salle_num | seance_date | film_titre |
|---|---|---|
| 3 | 03/10/2026 20:00 | Dune 2 |
| 1 | 04/10/2026 18:00 | Monte-Cristo |

### Reservation - clé (num_resa)
| num_resa | date_resa | client_email | salle_num | seance_date |
|---|---|---|---|---|
| 1001 | 01/10/2026 | karim@mail.fr | 3 | 03/10/2026 20:00 |
| 1002 | 01/10/2026 | julie@mail.fr | 3 | 03/10/2026 20:00 |
| 1003 | 02/10/2026 | karim@mail.fr | 1 | 04/10/2026 18:00 |

Plus **PlaceReservee** et **FilmGenre** (inchangées).

**Constat :** plus aucune redondance. Modifier la capacité de la salle 3 = modifier **une seule ligne**.

---

## 4. Forme normale de Boyce-Codd (BCNF)

**Règle :** pour toute dépendance X → Y, **X doit être une clé** (super-clé).
C'est une 3FN plus stricte.

**Vérification :** dans toutes nos tables, chaque colonne qui en détermine une autre est bien une clé. **Nos 7 tables sont en BCNF.**

**Exemple d'une table en 3FN mais PAS en BCNF** (affectation des projectionnistes) :
règle métier : *chaque projectionniste ne travaille que dans une seule salle*.

| salle_num | creneau | projectionniste |
|---|---|---|
| 1 | matin | Paul |
| 1 | soir | Léa |
| 3 | matin | Sami |

- Clé : (salle_num, creneau) → projectionniste
- Mais aussi : **projectionniste → salle_num**, et `projectionniste` n'est **pas une clé** : la BCNF est violée.
- Solution : `ProjectionnisteSalle(projectionniste, salle_num)` + `Affectation(projectionniste, creneau)`.

---

## 5. Bilan : du tableau Excel au diagramme de classes

| Table normalisée | Classe UML (06_diagramme_classes) |
|---|---|
| Client | Client |
| Salle | Salle |
| Film | Film |
| Seance | Seance |
| Reservation | Reservation |
| PlaceReservee | PlaceReservee (classe d'association) |
| FilmGenre | association Film * -- 1..* Genre (table de jonction) |

**On retombe sur le diagramme de classes.** Deux améliorations y sont déjà prévues :
- des **identifiants techniques** (`id`) au lieu de clés naturelles (l'e-mail ou le titre peuvent changer) ;
- **Realisateur** et **Genre** deviennent de vraies tables, pour stocker plus d'informations.