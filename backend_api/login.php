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

if (!isset($data['username']) || !isset($data['password'])) {
    echo json_encode(["status" => "error", "message" => "username & password required"]);
    exit;
}

$username = $conn->real_escape_string(trim($data['username']));
$password = $data['password'];

$check = $conn->query("SELECT id, password_hash, api_token, email FROM users WHERE username='$username' LIMIT 1");
if (!$check || $check->num_rows === 0) {
    echo json_encode(["status" => "error", "message" => "Invalid credentials"]);
    exit;
}

$row = $check->fetch_assoc();
if (!password_verify($password, $row['password_hash'])) {
    echo json_encode(["status" => "error", "message" => "Invalid credentials"]);
    exit;
}

// Ensure api_token exists
$token = $row['api_token'];
if (empty($token)) {
    $token = bin2hex(random_bytes(32));
    $uid = intval($row['id']);
    $conn->query("UPDATE users SET api_token='$token' WHERE id=$uid");
}

// include email and user_id if present
$email = isset($row['email']) ? $conn->real_escape_string($row['email']) : null;
$userId = intval($row['id']);
echo json_encode(["status" => "success", "api_token" => $conn->real_escape_string($token), "username" => $conn->real_escape_string($username), "email" => $email, "user_id" => $userId]);
$conn->close();
