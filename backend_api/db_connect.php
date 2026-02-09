<?php
$host = "127.0.0.1";
$port = 3306;
$user = "root";
$pass = "root";
$db   = "uangbro_db";
$socket = "/Applications/MAMP/tmp/mysql/mysql.sock";

$conn = new mysqli($host, $user, $pass, $db, $port, $socket);

if ($conn->connect_error) {
    header('Content-Type: application/json');
    echo json_encode(['status' => 'error', 'message' => 'Connection failed: ' . $conn->connect_error]);
    exit;
}
