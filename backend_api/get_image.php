<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: *");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

$file = $_GET['file'] ?? '';
$file = basename($file); // Security: prevent directory traversal

$path = __DIR__ . '/uploads/' . $file;

if (!file_exists($path) || !is_file($path)) {
    http_response_code(404);
    echo "File not found";
    exit;
}

$mime = mime_content_type($path);
header("Content-Type: $mime");
header("Content-Length: " . filesize($path));
readfile($path);
