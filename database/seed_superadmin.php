<?php
// Seeds the platform-owner Super Admin. CLI ONLY. Never reachable from a browser.
// Usage: php database/seed_superadmin.php "email" "password"

if (PHP_SAPI !== 'cli') {
    http_response_code(403);
    exit('Forbidden.');
}

require __DIR__ . '/../config/database.php';

if ($argc < 3) {
    exit("Usage: php database/seed_superadmin.php <email> <password>\n");
}

$email    = strtolower(trim($argv[1]));
$password = $argv[2];

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    exit("Invalid email address.\n");
}
if (strlen($password) < 8) {
    exit("Password must be at least 8 characters.\n");
}

$pdo = db();

$roleId = $pdo->query("SELECT id FROM roles WHERE name = 'super_admin'")->fetchColumn();
if (!$roleId) {
    exit("Roles table is empty. Import database/schema.sql first.\n");
}

$exists = $pdo->prepare('SELECT COUNT(*) FROM users WHERE role_id = ?');
$exists->execute([$roleId]);
if ((int) $exists->fetchColumn() > 0) {
    exit("A Super Admin already exists. Nothing changed.\n");
}

$stmt = $pdo->prepare(
    'INSERT INTO users (business_id, role_id, full_name, email, password_hash, can_approve, must_change_password)
     VALUES (NULL, ?, ?, ?, ?, 1, 1)'
);
$stmt->execute([
    $roleId,
    'Platform Owner',
    $email,
    password_hash($password, PASSWORD_DEFAULT),
]);

echo "Super Admin created: {$email}\n";