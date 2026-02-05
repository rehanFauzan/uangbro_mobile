<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");

echo json_encode([
    "status" => "API is running",
    "timestamp" => date('Y-m-d H:i:s'),
    "port" => $_SERVER['SERVER_PORT'] ?? 'unknown'
]);
?>