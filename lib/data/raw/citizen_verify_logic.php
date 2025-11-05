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
$citizen = $stmt->fetch();

if ($citizen) {
    return [
        'status' => 1,
        'data'   => [
            'user_id'      => $citizen['customer_id'],
            'user_name'    => $citizen['owner_name'],
            'role'         => 'citizen',
            'propertyName' => $citizen['property_name'],
        ],
        'token'  => bin2hex(random_bytes(16)),
    ];
}

return ['status' => 2, 'message' => 'NEW_USER'];
?>
