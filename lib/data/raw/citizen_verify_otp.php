<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);

$response = require __DIR__ . '/citizen_verify_logic.php';
jsonResponse($response);
?>
