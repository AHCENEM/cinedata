<?php
// CinéData - modèle de configuration
// 1. Copier ce fichier sous le nom config.php
// 2. Remplacer A_REMPLACER par le vrai mot de passe
// config.php est ignoré par Git (.gitignore) : le mot de passe n'est jamais publié
return [
    'dsn'      => 'mysql:host=localhost;dbname=cinedata;charset=utf8mb4',
    'user'     => 'cinedata_dev',
    'password' => 'A_REMPLACER',
];