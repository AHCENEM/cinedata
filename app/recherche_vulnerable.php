<?php
// CinéData - recherche de client : VERSION VULNÉRABLE
// À NE JAMAIS FAIRE EN PRODUCTION : démonstration pédagogique
$config = require __DIR__ . '/config.php';

$pdo = new PDO($config['dsn'], $config['user'], $config['password'], [
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::MYSQL_ATTR_MULTI_STATEMENTS => false,
]);

$email     = $_GET['email'] ?? '';
$resultats = [];
$sql       = '';
$erreur    = '';

if ($email !== '') {
    // FAILLE : la saisie de l'utilisateur est collée directement dans la requête
    $sql = "SELECT p.prenom, p.nom, p.email, p.telephone
            FROM personne p JOIN client c ON c.id = p.id
            WHERE p.email = '" . $email . "'";
    try {
        $resultats = $pdo->query($sql)->fetchAll();
    } catch (PDOException $e) {
        $erreur = $e->getMessage();
    }
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <title>Recherche VULNÉRABLE</title>
  <style>
    body { font-family: Arial, sans-serif; max-width: 900px; margin: 40px auto; padding: 0 16px; }
    h1 { color: #c0392b; }
    input[type=text] { width: 320px; padding: 6px; }
    pre { background: #f4f4f4; padding: 10px; white-space: pre-wrap; }
    table { border-collapse: collapse; margin-top: 12px; }
    th, td { border: 1px solid #ccc; padding: 6px 10px; }
  </style>
</head>
<body>
  <h1>Recherche de client - version VULNÉRABLE</h1>
  <form method="get">
    <input type="text" name="email" placeholder="e-mail du client"
           value="<?= htmlspecialchars($email) ?>">
    <button type="submit">Rechercher</button>
  </form>

  <?php if ($sql !== ''): ?>
    <h3>Requête réellement envoyée à la base :</h3>
    <pre><?= htmlspecialchars($sql) ?></pre>
    <?php if ($erreur !== ''): ?>
      <p style="color:#c0392b">Erreur SQL : <?= htmlspecialchars($erreur) ?></p>
    <?php else: ?>
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
  <?php endif; ?>

  <p><a href="index.php">Retour</a></p>
</body>
</html>