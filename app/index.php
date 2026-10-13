<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <title>CinéData - Démonstration injection SQL</title>
  <style>
    body { font-family: Arial, sans-serif; max-width: 800px; margin: 40px auto; padding: 0 16px; }
    a { display: block; margin: 12px 0; font-size: 18px; }
    .danger { color: #c0392b; }
    .ok { color: #27ae60; }
  </style>
</head>
<body>
  <h1>CinéData - Sécurité : injection SQL</h1>
  <p>Deux versions de la même recherche de client par e-mail :</p>
  <a class="danger" href="recherche_vulnerable.php">1. Version VULNÉRABLE (concaténation)</a>
  <a class="ok" href="recherche_securisee.php">2. Version SÉCURISÉE (requête préparée PDO)</a>
  <p>Saisie de test : <code>karim.benali@mail.fr</code> puis <code>' OR '1'='1</code></p>
</body>
</html>