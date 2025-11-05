# Citizen OTP API Samples

Minimal PHP snippets for the new OTP + registration flow. These are templates —
adjust namespaces, database credentials, and hardening (rate limits, CSRF,
HTTPS redirects) before deploying.

```php
<?php
// db.php — centralises PDO connection
$dbHost = 'localhost';
$dbName = 'iwms';
$dbUser = 'YOUR_DB_USER';
$dbPass = 'YOUR_DB_PASS';

try {
    $pdo = new PDO("mysql:host=$dbHost;dbname=$dbName;charset=utf8mb4", $dbUser, $dbPass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['status' => 0, 'error' => 'Database connection failed']);
    exit;
}

function jsonResponse(array $payload) {
    header('Content-Type: application/json');
    echo json_encode($payload);
    exit;
}
```

## 1. citizen_request_otp.php

```php
<?php
require_once 'db.php';

$phone = trim($_POST['phone'] ?? '');
if ($phone === '') {
    jsonResponse(['status' => 0, 'error' => 'Phone is required']);
}

$otp = random_int(100000, 999999);
$expiresAt = (new DateTime('+5 minutes'))->format('Y-m-d H:i:s');

$stmt = $pdo->prepare('REPLACE INTO otp_codes (phone, code, expires_at, attempts) VALUES (:phone, :code, :expires_at, 0)');
$stmt->execute([
    ':phone' => $phone,
    ':code' => $otp,
    ':expires_at' => $expiresAt,
]);

// TODO: Send the OTP via SMS gateway. For dev/testing, you may return it.
jsonResponse(['status' => 1, 'message' => 'OTP sent']);
```

## 2. citizen_verify_otp.php

```php
<?php
require_once 'db.php';

$phone = trim($_POST['phone'] ?? '');
$otp = trim($_POST['otp'] ?? '');
if ($phone === '' || $otp === '') {
    jsonResponse(['status' => 0, 'error' => 'Phone and OTP are required']);
}

$stmt = $pdo->prepare('SELECT * FROM otp_codes WHERE phone = :phone');
$stmt->execute([':phone' => $phone]);
$record = $stmt->fetch();

if (!$record) {
    jsonResponse(['status' => 0, 'error' => 'OTP not requested']);
}

$now = new DateTime();
$expiresAt = new DateTime($record['expires_at']);

if ($record['attempts'] >= 5) {
    jsonResponse(['status' => 0, 'error' => 'Too many attempts. Request a new OTP.']);
}

if ($now > $expiresAt || $record['code'] !== $otp) {
    $pdo->prepare('UPDATE otp_codes SET attempts = attempts + 1 WHERE phone = :phone')
        ->execute([':phone' => $phone]);
    jsonResponse(['status' => 0, 'error' => 'Invalid or expired OTP']);
}

// OTP valid — clear attempts
$pdo->prepare('UPDATE otp_codes SET attempts = 0 WHERE phone = :phone')
    ->execute([':phone' => $phone]);

// Check if the citizen already exists
$citizenStmt = $pdo->prepare('SELECT customer_id AS user_id, owner_name AS user_name FROM customer_creation WHERE contact_no = :phone AND is_delete = 0 LIMIT 1');
$citizenStmt->execute([':phone' => $phone]);
$citizen = $citizenStmt->fetch();

if ($citizen) {
    jsonResponse([
        'status' => 1,
        'data' => [
            'user_id' => $citizen['user_id'],
            'user_name' => $citizen['user_name'],
            'role' => 'citizen',
        ],
        'token' => bin2hex(random_bytes(16)),
    ]);
}

jsonResponse([
    'status' => 2,
    'message' => 'NEW_USER',
]);
```

## 3. citizen_register.php

```php
<?php
require_once 'db.php';

$required = [
    'phone', 'otp', 'owner_name', 'contact_no', 'building_no', 'street', 'area',
    'pincode', 'city', 'district', 'state', 'zone', 'ward', 'property_name',
];

foreach ($required as $field) {
    if (trim($_POST[$field] ?? '') === '') {
        jsonResponse(['status' => 0, 'error' => "$field is required"]);
    }
}

$phone = trim($_POST['phone']);
$otp = trim($_POST['otp']);

// Re-use verification logic
$_POST['phone'] = $phone;
$_POST['otp'] = $otp;
require 'citizen_verify_otp.php';
```

_Tip_: move the shared OTP validation into a function to avoid including the
file twice. After validating the OTP, generate IDs and insert into
`customer_creation`.

```php
$uniqueId = 'CUS-' . bin2hex(random_bytes(6));
$customerId = sprintf('CUS-%s-%04d', date('my'), random_int(1, 9999));

$insert = $pdo->prepare('INSERT INTO customer_creation (
    unique_id, customer_id, owner_name, contact_no, building_no, street, area,
    pincode, city, district, state, zone, ward, property_name, id_type, id_no,
    lattitude, longitude, acc_year, session_id, sess_user_type, sess_user_id,
    sess_company_id, sess_branch_id
) VALUES (
    :unique_id, :customer_id, :owner_name, :contact_no, :building_no, :street, :area,
    :pincode, :city, :district, :state, :zone, :ward, :property_name, '', '',
    '', '', :acc_year, '', '', '', '', ''
)');

$insert->execute([
    ':unique_id' => $uniqueId,
    ':customer_id' => $customerId,
    ':owner_name' => trim($_POST['owner_name']),
    ':contact_no' => trim($_POST['contact_no']),
    ':building_no' => trim($_POST['building_no']),
    ':street' => trim($_POST['street']),
    ':area' => trim($_POST['area']),
    ':pincode' => trim($_POST['pincode']),
    ':city' => trim($_POST['city']),
    ':district' => trim($_POST['district']),
    ':state' => trim($_POST['state']),
    ':zone' => trim($_POST['zone']),
    ':ward' => trim($_POST['ward']),
    ':property_name' => trim($_POST['property_name']),
    ':acc_year' => date('Y') . '-' . (date('Y') + 1),
]);

jsonResponse([
    'status' => 1,
    'data' => [
        'user_id' => $customerId,
        'user_name' => trim($_POST['owner_name']),
        'role' => 'citizen',
    ],
    'token' => bin2hex(random_bytes(16)),
]);
```

## 4. citizen_login_otp.php

Reuse the verification script and only return success when the citizen exists.

```php
<?php
require_once 'db.php';

$phone = trim($_POST['phone'] ?? '');
$otp = trim($_POST['otp'] ?? '');

// Re-use verification logic but reject status 2 (new user)
$verification = include 'citizen_verify_logic.php'; // return associative array

if ($verification['status'] === 1) {
    jsonResponse($verification);
}

jsonResponse(['status' => 0, 'error' => 'Citizen not registered']);
```

### OTP table helper

```sql
CREATE TABLE IF NOT EXISTS otp_codes (
  phone VARCHAR(20) PRIMARY KEY,
  code VARCHAR(6) NOT NULL,
  expires_at DATETIME NOT NULL,
  attempts INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

> **Security checklist**
>
> * Serve these endpoints over HTTPS only.
> * Rate-limit OTP requests and responses.
> * Purge expired OTP rows periodically.
> * Use a real SMS provider before going live.
> * Sanitize/validate all inputs server-side (length, format, ward/zone IDs).
