// =========================================================
// CinéData - 11_avis_nosql.js (MongoDB 9 / mongosh 2)
// Données orientées documents : avis clients et journaux de navigation
// Lancement : mongosh --quiet --file mongo\11_avis_nosql.js
// =========================================================

// Petite fonction d'affichage pour séparer les étapes
function titre(t) {
  print("\n==================================================");
  print(" " + t);
  print("==================================================");
}

// On travaille dans une base dédiée (créée automatiquement au 1er insert)
db = db.getSiblingDB("cinedata_nosql");
db.dropDatabase();   // pour pouvoir relancer le script

// #########################################################
// 1. VALIDATION DE SCHÉMA : un schéma flexible... mais encadré
// #########################################################
db.createCollection("avis", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["film", "note", "date"],
      properties: {
        note: { bsonType: "number", minimum: 1, maximum: 5,
                description: "note obligatoire, de 1 à 5" },
        film: { bsonType: "object", required: ["id", "titre"] },
        tags: { bsonType: "array", items: { bsonType: "string" } }
      }
    }
  }
});

// #########################################################
// 2. INSERTION : des documents de STRUCTURES DIFFÉRENTES
// #########################################################
titre("1 - insertMany : 7 avis, chacun avec sa propre structure");

const resultat = db.avis.insertMany([
  {
    film: { id: 1, titre: "Les Dunes d'Argent" },
    client: { pseudo: "karim_b", tranche_age: "35-44" },
    note: 5,
    commentaire: "Visuellement incroyable, à voir en IMAX.",
    date: new Date("2026-09-08"),
    tags: ["visuel", "imax", "sf"],
    likes: 12,
    reponses: [
      { auteur: "julie_m", texte: "Entièrement d'accord !", date: new Date("2026-09-09") }
    ]
  },
  {
    film: { id: 1, titre: "Les Dunes d'Argent" },
    client: { pseudo: "julie_m", tranche_age: "35-44" },
    note: 4,
    commentaire: "Très bon, un peu long.",
    date: new Date("2026-09-07"),
    tags: ["long", "sf"],
    likes: 3
  },
  {
    film: { id: 3, titre: "Nuit Blanche à Marseille" },
    client: { pseudo: "thomas_d" },                      // pas de tranche d'âge
    note: 3,
    date: new Date("2026-09-22"),                        // pas de commentaire
    likes: 0
  },
  {
    film: { id: 4, titre: "Le Jardin des Lucioles" },
    client: { pseudo: "linh_n", tranche_age: "25-34" },
    note: 5,
    commentaire: "Magnifique, mes enfants ont adoré.",
    date: new Date("2026-10-05"),
    tags: ["famille", "emotion"],
    likes: 8,
    contexte: { venu_avec: "enfants", nb_personnes: 3 }  // champ propre à cet avis
  },
  {
    film: { id: 2, titre: "Le Secret de Monte-Verde" },
    client: { pseudo: "hugo_l", tranche_age: "45-54" },
    note: 2,
    commentaire: "Je me suis ennuyé, et la fin est prévisible.",
    date: new Date("2026-09-14"),
    spoiler: true,                                       // champ présent sur 1 seul avis
    likes: 1
  },
  {
    film: { id: 2, titre: "Le Secret de Monte-Verde" },
    client: { pseudo: "karim_b", tranche_age: "35-44" },
    note: 4,
    commentaire: "Belle adaptation.",
    date: new Date("2026-09-13"),
    tags: ["adaptation", "drame"],
    likes: 5
  },
  {
    film: { id: 5, titre: "Point de Rupture" },
    client: { pseudo: "aminata_d", tranche_age: "25-34" },
    note: 4,
    commentaire: "Tendu du début à la fin.",
    date: new Date("2026-10-11"),
    tags: ["thriller", "suspense", "sf"],
    likes: 6
  }
]);
print("Documents insérés : " + Object.keys(resultat.insertedIds).length);

// Journaux de navigation : chaque type d'événement a SES champs
db.logs_navigation.insertMany([
  { type: "page_vue",     session: "s1", page: "/programme",      date: new Date("2026-10-12T10:00:00") },
  { type: "recherche",    session: "s1", terme: "dunes",          nb_resultats: 1, date: new Date("2026-10-12T10:00:20") },
  { type: "page_vue",     session: "s1", page: "/film/1",         date: new Date("2026-10-12T10:00:35") },
  { type: "ajout_panier", session: "s1", seance: 9, nb_places: 2, date: new Date("2026-10-12T10:02:10") },
  { type: "paiement",     session: "s1", montant: 23.00, moyen: "CB", date: new Date("2026-10-12T10:03:00") },
  { type: "page_vue",     session: "s2", page: "/programme",      date: new Date("2026-10-12T11:15:00") },
  { type: "recherche",    session: "s2", terme: "enfants",        nb_resultats: 0, date: new Date("2026-10-12T11:15:30") },
  { type: "page_vue",     session: "s3", page: "/programme",      date: new Date("2026-10-12T14:40:00") },
  { type: "page_vue",     session: "s3", page: "/film/5",         date: new Date("2026-10-12T14:41:00") },
  { type: "ajout_panier", session: "s3", seance: 11, nb_places: 1, date: new Date("2026-10-12T14:42:30") }
]);
print("Événements de navigation : " + db.logs_navigation.countDocuments());

// 2b. La validation refuse un avis noté 6
titre("2 - validation $jsonSchema : un avis noté 6 est refusé");
try {
  db.avis.insertOne({ film: { id: 1, titre: "Test" }, note: 6, date: new Date() });
  print("ÉCHEC : l'avis invalide a été accepté");
} catch (e) {
  print("Refusé comme prévu : " + e.message.split("\n")[0]);
}

// #########################################################
// 3. LECTURE : find, filtres, projection, tri
// #########################################################
titre("3a - find : avis notés 4 ou plus ($gte), triés par likes");
printjson(
  db.avis.find(
    { note: { $gte: 4 } },                                   // filtre (WHERE)
    { _id: 0, "film.titre": 1, note: 1, likes: 1 }           // projection (SELECT colonnes)
  ).sort({ likes: -1 }).toArray()                            // ORDER BY likes DESC
);

titre("3b - champ imbriqué : avis sur Les Dunes d'Argent (\"film.titre\")");
printjson(
  db.avis.find({ "film.titre": "Les Dunes d'Argent" },
               { _id: 0, "client.pseudo": 1, note: 1 }).toArray()
);

titre("3c - recherche dans un tableau : avis taggés \"sf\"");
printjson(
  db.avis.find({ tags: "sf" }, { _id: 0, "film.titre": 1, tags: 1 }).toArray()
);

titre("3d - $exists : avis SANS commentaire / avis marqués spoiler");
print("Sans commentaire : " + db.avis.countDocuments({ commentaire: { $exists: false } }));
print("Avec spoiler     : " + db.avis.countDocuments({ spoiler: true }));

titre("3e - $in + limit : 2 premiers avis des films 2 et 5");
printjson(
  db.avis.find({ "film.id": { $in: [2, 5] } }, { _id: 0, "film.titre": 1, note: 1 })
         .sort({ date: 1 }).limit(2).toArray()
);

// #########################################################
// 4. MODIFICATION : $set, $inc, $push
// #########################################################
titre("4 - updateOne : $inc (likes), $push (réponse), $set (modération)");
db.avis.updateOne(
  { "client.pseudo": "aminata_d" },
  {
    $inc:  { likes: 1 },                                     // likes = likes + 1
    $push: { reponses: { auteur: "karim_b", texte: "Je confirme, quel suspense !", date: new Date() } },
    $set:  { modere: true }                                  // ajoute un champ qui n'existait pas
  }
);
printjson(
  db.avis.findOne({ "client.pseudo": "aminata_d" },
                  { _id: 0, likes: 1, modere: 1, reponses: 1 })
);

// #########################################################
// 5. AGRÉGATION : les indicateurs (équivalent de GROUP BY)
// #########################################################
titre("5a - note moyenne et nombre d'avis par film ($group, $avg)");
printjson(
  db.avis.aggregate([
    { $group: {
        _id: "$film.titre",
        note_moyenne: { $avg: "$note" },
        nb_avis: { $sum: 1 },
        total_likes: { $sum: "$likes" }
    } },
    { $project: { _id: 0, film: "$_id", note_moyenne: { $round: ["$note_moyenne", 2] }, nb_avis: 1, total_likes: 1 } },
    { $sort: { note_moyenne: -1, nb_avis: -1 } }
  ]).toArray()
);

titre("5b - tags les plus utilisés ($unwind = déplier un tableau)");
printjson(
  db.avis.aggregate([
    { $unwind: "$tags" },
    { $group: { _id: "$tags", nb: { $sum: 1 } } },
    { $sort: { nb: -1, _id: 1 } },
    { $limit: 5 }
  ]).toArray()
);

titre("5c - entonnoir de conversion : nombre de sessions par étape");
printjson(
  db.logs_navigation.aggregate([
    { $group: { _id: "$type", sessions: { $addToSet: "$session" } } },
    { $project: { _id: 0, etape: "$_id", nb_sessions: { $size: "$sessions" } } },
    { $sort: { nb_sessions: -1 } }
  ]).toArray()
);

titre("5d - recherches sans résultat (idées de films à programmer)");
printjson(
  db.logs_navigation.find({ type: "recherche", nb_resultats: 0 },
                          { _id: 0, terme: 1, session: 1 }).toArray()
);

// #########################################################
// 6. INDEX ET EXPLAIN
// #########################################################
titre("6 - explain avant / après index sur film.id");
const avant = db.avis.find({ "film.id": 2 }).explain("executionStats");
print("AVANT : étape = " + avant.queryPlanner.winningPlan.stage
      + " | documents examinés = " + avant.executionStats.totalDocsExamined);

db.avis.createIndex({ "film.id": 1 });

const apres = db.avis.find({ "film.id": 2 }).explain("executionStats");
const etape = apres.queryPlanner.winningPlan.inputStage
              ? apres.queryPlanner.winningPlan.inputStage.stage
              : apres.queryPlanner.winningPlan.stage;
print("APRÈS : étape = " + etape
      + " | documents examinés = " + apres.executionStats.totalDocsExamined);
print("Index de la collection avis :");
printjson(db.avis.getIndexes().map(i => i.name));

// #########################################################
// 7. SUPPRESSION
// #########################################################
titre("7 - deleteMany : purge des événements de la session s2");
const suppr = db.logs_navigation.deleteMany({ session: "s2" });
print("Événements supprimés : " + suppr.deletedCount);
print("Événements restants  : " + db.logs_navigation.countDocuments());

// #########################################################
// BILAN
// #########################################################
titre("BILAN");
print("Collections : " + db.getCollectionNames().join(", "));
print("Avis        : " + db.avis.countDocuments());
print("Événements  : " + db.logs_navigation.countDocuments());
