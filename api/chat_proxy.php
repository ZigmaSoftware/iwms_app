<?php
/**
 * Local PHP proxy that forwards chat prompts to the external AI provider.
 *
 * SECURITY NOTE:
 *  - Replace the placeholder endpoint/model below with your real provider info.
 *  - Never commit the real AI key to source control; load it from an .env file
 *    or server config instead. For local testing you can create a `.env` file
 *    that is gitignored and populate AI_KEY there.
 */

// Basic CORS handling (tighten the origin list for production use).
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
    exit;
}

$rawBody = file_get_contents('php://input');
$body = json_decode($rawBody, true);

if (!is_array($body) || empty($body['prompt'])) {
    http_response_code(400);
    echo json_encode(['error' => 'Missing prompt data']);
    exit;
}

$aiKey = getenv('AI_KEY');
if (!$aiKey) {
    http_response_code(500);
    echo json_encode(['error' => 'AI key is not configured on the server']);
    exit;
}

$payload = [
    'model' => 'gpt-3.5',
    'messages' => $body['prompt'],
];

$ch = curl_init('https://api.provider.com/v1/chat');
curl_setopt_array($ch, [
    CURLOPT_POST => true,
    CURLOPT_HTTPHEADER => [
        'Authorization: Bearer ' . $aiKey,
        'Content-Type: application/json',
    ],
    CURLOPT_POSTFIELDS => json_encode($payload),
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_TIMEOUT => 30,
]);

$response = curl_exec($ch);
$status = curl_getinfo($ch, CURLINFO_HTTP_CODE);

if ($response === false) {
    http_response_code(502);
    echo json_encode(['error' => 'Failed to contact AI provider']);
    curl_close($ch);
    exit;
}

curl_close($ch);
http_response_code($status ?: 200);
echo $response;
