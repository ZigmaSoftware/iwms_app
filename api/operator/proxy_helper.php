<?php

declare(strict_types=1);

/**
 * Simple pass-through proxy for PHP-based endpoints so the mobile app can hit a
 * single domain while the actual logic remains on the IWMS backend.
 */
function forward_request(string $targetUrl): void
{
    $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
    $query = $_SERVER['QUERY_STRING'] ?? '';

    if ($method === 'GET' && !empty($query)) {
        $targetUrl .= (str_contains($targetUrl, '?') ? '&' : '?') . $query;
    }

    $ch = curl_init($targetUrl);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_FOLLOWLOCATION => true,
        CURLOPT_TIMEOUT => 30,
        CURLOPT_CONNECTTIMEOUT => 10,
    ]);

    if ($method === 'POST') {
        curl_setopt($ch, CURLOPT_POST, true);
        $fields = prepare_post_fields();
        curl_setopt($ch, CURLOPT_POSTFIELDS, $fields);
    }

    $response = curl_exec($ch);
    $status = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);

    if ($response === false) {
        http_response_code(502);
        header('Content-Type: application/json');
        echo json_encode([
            'status' => 'error',
            'message' => 'Upstream request failed: ' . curl_error($ch),
        ]);
    } else {
        if (!headers_sent()) {
            header('Content-Type: application/json');
            http_response_code($status > 0 ? $status : 200);
        }
        echo $response;
    }

    curl_close($ch);
}

function prepare_post_fields(): array
{
    $fields = $_POST;
    foreach ($_FILES as $name => $file) {
        if (is_array($file['tmp_name'])) {
            // Handle multi-file inputs (not used today but keeps things safe).
            foreach ($file['tmp_name'] as $idx => $tmpName) {
                if ($tmpName === '') {
                    continue;
                }
                $fields[$name][$idx] = new CURLFile(
                    $tmpName,
                    $file['type'][$idx] ?? 'application/octet-stream',
                    $file['name'][$idx] ?? 'upload.bin'
                );
            }
        } elseif ($file['tmp_name'] !== '') {
            $fields[$name] = new CURLFile(
                $file['tmp_name'],
                $file['type'] ?? 'application/octet-stream',
                $file['name'] ?? 'upload.bin'
            );
        }
    }

    return $fields;
}
