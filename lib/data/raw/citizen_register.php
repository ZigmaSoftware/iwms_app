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

$required = [
    'phone', 'owner_name', 'contact_no', 'building_no', 'street',
    'area', 'pincode', 'city', 'district', 'state', 'zone', 'ward', 'property_name'
];

foreach ($required as $field) {
    if (trim($_POST[$field] ?? '') === '') {
        jsonResponse(['status' => 0, 'error' => "$field is required"], 400);
    }
}

$phone      = trim($_POST['phone']);
$contactNo  = trim($_POST['contact_no']);
$ownerName  = trim($_POST['owner_name']);
$buildingNo = trim($_POST['building_no']);
$street     = trim($_POST['street']);
$area       = trim($_POST['area']);
$pincode    = trim($_POST['pincode']);
$city       = trim($_POST['city']);
$district   = trim($_POST['district']);
$state      = trim($_POST['state']);
$zone       = trim($_POST['zone']);
$ward       = trim($_POST['ward']);
$property   = trim($_POST['property_name']);

if ($contactNo === '') {
    $contactNo = $phone;
}

try {
    $pdo->beginTransaction();

    $lookup = $pdo->prepare(
        'SELECT id, customer_id, unique_id
           FROM citizen_profiles
          WHERE contact_no = :contact_no OR phone = :phone
          LIMIT 1 FOR UPDATE'
    );
    $lookup->execute([
        ':contact_no' => $contactNo,
        ':phone'      => $phone,
    ]);
    $existing = $lookup->fetch();

    if ($existing) {
        $customerId = $existing['customer_id'];
        $update = $pdo->prepare(
            'UPDATE citizen_profiles
                SET owner_name    = :owner_name,
                    phone         = :phone,
                    contact_no    = :contact_no,
                    building_no   = :building_no,
                    street        = :street,
                    area          = :area,
                    pincode       = :pincode,
                    city          = :city,
                    district      = :district,
                    state         = :state,
                    zone          = :zone,
                    ward          = :ward,
                    property_name = :property_name,
                    is_active     = 1,
                    updated_at    = CURRENT_TIMESTAMP
              WHERE id = :id'
        );
        $update->execute([
            ':owner_name'    => $ownerName,
            ':phone'         => $phone,
            ':contact_no'    => $contactNo,
            ':building_no'   => $buildingNo,
            ':street'        => $street,
            ':area'          => $area,
            ':pincode'       => $pincode,
            ':city'          => $city,
            ':district'      => $district,
            ':state'         => $state,
            ':zone'          => $zone,
            ':ward'          => $ward,
            ':property_name' => $property,
            ':id'            => $existing['id'],
        ]);
    } else {
        $uniqueId   = 'CUS-' . strtoupper(bin2hex(random_bytes(4)));

        $attempts = 5;
        do {
            $customerId = sprintf(
                'CUS-%s-%06d',
                date('ym'),
                random_int(0, 999999)
            );
            $checkId = $pdo->prepare(
                'SELECT 1 FROM citizen_profiles WHERE customer_id = :customer_id LIMIT 1'
            );
            $checkId->execute([':customer_id' => $customerId]);
            $exists = (bool) $checkId->fetchColumn();
        } while ($exists && --$attempts > 0);

        if (!empty($exists)) {
            throw new RuntimeException('Could not allocate unique customer ID');
        }

        $insert = $pdo->prepare(
            'INSERT INTO citizen_profiles (
                unique_id, customer_id, phone, owner_name, contact_no,
                building_no, street, area, pincode, city, district, state,
                zone, ward, property_name, is_active
            ) VALUES (
                :unique_id, :customer_id, :phone, :owner_name, :contact_no,
                :building_no, :street, :area, :pincode, :city, :district, :state,
                :zone, :ward, :property_name, 1
            )'
        );
        $insert->execute([
            ':unique_id'     => $uniqueId,
            ':customer_id'   => $customerId,
            ':phone'         => $phone,
            ':owner_name'    => $ownerName,
            ':contact_no'    => $contactNo,
            ':building_no'   => $buildingNo,
            ':street'        => $street,
            ':area'          => $area,
            ':pincode'       => $pincode,
            ':city'          => $city,
            ':district'      => $district,
            ':state'         => $state,
            ':zone'          => $zone,
            ':ward'          => $ward,
            ':property_name' => $property,
        ]);
    }

    $pdo->commit();
} catch (Throwable $exception) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    error_log('Citizen registration failed: ' . $exception->getMessage());
    jsonResponse([
        'status' => 0,
        'error'  => 'Unable to complete registration',
        'error_detail' => $exception->getMessage(),
    ], 500);
}

jsonResponse([
    'status' => 1,
    'data'   => [
        'user_id'   => $customerId,
        'user_name' => $ownerName,
        'role'      => 'citizen',
    ],
    'token'  => bin2hex(random_bytes(16)),
]);
?>
