<?php
// Shared PDO connection. XAMPP defaults (root, no password) are DEVELOPMENT ONLY.
// For any real deployment, create config/database.local.php (git-ignored) returning
// an array with host, name, user, pass to override these defaults.

function db(): PDO
{
    static $pdo = null;
    if ($pdo instanceof PDO) {
        return $pdo;
    }

    $cfg = [
        'host' => '127.0.0.1',
        'name' => 'business_workflow',
        'user' => 'root',
        'pass' => '',
    ];

    $local = __DIR__ . '/database.local.php';
    if (is_file($local)) {
        $cfg = array_merge($cfg, require $local);
    }

    $dsn = "mysql:host={$cfg['host']};dbname={$cfg['name']};charset=utf8mb4";

    try {
        $pdo = new PDO($dsn, $cfg['user'], $cfg['pass'], [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES   => false,
        ]);
    } catch (PDOException $e) {
        error_log('DB connection failed: ' . $e->getMessage());
        http_response_code(500);
        exit('Database connection failed. Check that MySQL is running and the schema is imported.');
    }

    return $pdo;
}