<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

ini_set('display_errors', 1);
error_reporting(E_ALL);

require_once __DIR__ . '/db.php';

$phone = trim($_POST['phone'] ?? '');
if ($phone === '') {
    jsonResponse(['status' => 0, 'error' => 'Phone is required'], 400);
}

$stmt = $pdo->prepare(
    'SELECT customer_id, owner_name, property_name
       FROM citizen_profiles
      WHERE (phone = :phone OR contact_no = :phone)
        AND (is_active IS NULL OR is_active = 1)
      LIMIT 1'
);
$stmt->execute([':phone' => $phone]);
$profile = $stmt->fetch();

if (!$profile) {
    jsonResponse(['status' => 0, 'error' => 'Citizen not registered'], 404);
}

jsonResponse([
    'status' => 1,
    'data'   => [
        'user_id'      => $profile['customer_id'],
        'user_name'    => $profile['owner_name'],
        'role'         => 'citizen',
        'propertyName' => $profile['property_name'],
    ],
    'token'  => bin2hex(random_bytes(16)),
]);
?>
