<?php
// =========================================================
// CinéData - recherche de client : VERSION SÉCURISÉE
// Requête préparée PDO : la saisie est toujours traitée comme une donnée
// =========================================================
$config = require __DIR__ . '/config.php';

$pdo = new PDO($config['dsn'], $config['user'], $config['password'], [
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::ATTR_EMULATE_PREPARES   => false,   // vraies requêtes préparées côté serveur
]);

$email     = $_GET['email'] ?? '';
$resultats = [];

if ($email !== '') {
    // ✅ La requête et la donnée sont envoyées SÉPARÉMENT
    $requete = $pdo->prepare(
        "SELECT p.prenom, p.nom, p.email, p.telephone
         FROM personne p JOIN client c ON c.id = p.id
         WHERE p.email = :email"
    );
    $requete->execute(['email' => $email]);
    $resultats = $requete->fetchAll();
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <title>Recherche SÉCURISÉE</title>
  <style>
    body { font-family: Arial, sans-serif; max-width: 900px; margin: 40px auto; padding: 0 16px; }
    h1 { color: #27ae60; }
    input[type=text] { width: 320px; padding: 6px; }
    pre { background: #f4f4f4; padding: 10px; white-space: pre-wrap; }
    table { border-collapse: collapse; margin-top: 12px; }
    th, td { border: 1px solid #ccc; padding: 6px 10px; }
  </style>
</head>
<body>
  <h1>✅ Recherche de client - version SÉCURISÉE</h1>
  <form method="get">
    <input type="text" name="email" placeholder="e-mail du client"
           value="<?= htmlspecialchars($email) ?>">
    <button type="submit">Rechercher</button>
  </form>

  <?php if ($email !== ''): ?>
    <h3>Requête préparée envoyée à la base :</h3>
    <pre>SELECT ... WHERE p.email = :email</pre>
    <h3>Valeur transmise séparément pour :email :</h3>
    <pre><?= htmlspecialchars($email) ?></pre>

    <p><strong><?= count($resultats) ?></strong> client(s) trouvé(s)</p>
    <table>
      <tr><th>Prénom</th><th>Nom</th><th>E-mail</th><th>Téléphone</th></tr>
      <?php foreach ($resultats as $ligne): ?>
        <tr>
          <td><?= htmlspecialchars($ligne['prenom']) ?></td>
          <td><?= htmlspecialchars($ligne['nom']) ?></td>
          <td><?= htmlspecialchars($ligne['email']) ?></td>
          <td><?= htmlspecialchars((string) $ligne['telephone']) ?></td>
        </tr>
      <?php endforeach; ?>
    </table>
  <?php endif; ?>

  <p><a href="index.php">← Retour</a></p>
</body>
</html>
