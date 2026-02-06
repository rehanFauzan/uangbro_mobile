<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

include 'db_connect.php';

$method = $_SERVER['REQUEST_METHOD'];
if ($method == 'OPTIONS') {
    http_response_code(200);
    exit();
}

$input = file_get_contents('php://input');
$data = json_decode($input, true) ?: $_POST;

if (!isset($data['username']) || !isset($data['password']) || !isset($data['email'])) {
    echo json_encode(["status" => "error", "message" => "username, password & email required"]);
    exit;
}

$username = $conn->real_escape_string(trim($data['username']));
$password = $data['password'];
$email = $conn->real_escape_string(trim($data['email']));

// Check if exists
$check = $conn->query("SELECT id FROM users WHERE username='$username' LIMIT 1");
if ($check && $check->num_rows > 0) {
    echo json_encode(["status" => "error", "message" => "Username already exists"]);
    exit;
}

$hash = password_hash($password, PASSWORD_BCRYPT);
$token = bin2hex(random_bytes(32));

// Insert with email column (assumes users table has `email` column)
$sql = "INSERT INTO users (username, password_hash, api_token, email) VALUES ('$username', '$hash', '$token', '$email')";
if ($conn->query($sql) === TRUE) {
    echo json_encode(["status" => "success", "api_token" => $conn->real_escape_string($token), "username" => $conn->real_escape_string($username), "email" => $conn->real_escape_string($email)]);
} else {
    echo json_encode(["status" => "error", "message" => "DB error: " . $conn->error]);
}

$conn->close();
