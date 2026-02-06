<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-API-Token");

include 'db_connect.php';

$method = $_SERVER['REQUEST_METHOD'];
if ($method == 'OPTIONS') {
    http_response_code(200);
    exit();
}

$input = file_get_contents('php://input');
$data = json_decode($input, true) ?: $_POST;

// Normalize headers to be case-insensitive
$headers = array_change_key_case(getallheaders(), CASE_LOWER);
$token = null;
if (isset($headers['authorization'])) {
    $auth = $headers['authorization'];
    if (stripos($auth, 'bearer ') === 0) {
        $token = substr($auth, 7);
    } else {
        $token = $auth;
    }
} elseif (isset($headers['x-api-token'])) {
    $token = $headers['x-api-token'];
}

if (empty($token)) {
    echo json_encode(["status" => "error", "message" => "Unauthorized"]);
    exit;
}

$token = $conn->real_escape_string($token);
$q = $conn->query("SELECT id FROM users WHERE api_token='$token' LIMIT 1");
if (!$q || $q->num_rows === 0) {
    echo json_encode(["status" => "error", "message" => "Invalid token"]);
    exit;
}
$user = $q->fetch_assoc();
$uid = intval($user['id']);

$updates = [];

if (isset($data['username'])) {
    $username = $conn->real_escape_string(trim($data['username']));
    if ($username !== '') {
        $updates[] = "username='$username'";
    }
}

if (isset($data['image_base64']) && !empty($data['image_base64'])) {
    $b64 = $data['image_base64'];
    $img = base64_decode($b64);
    if ($img === false) {
        echo json_encode(["status" => "error", "message" => "Invalid image data"]);
        exit;
    }
    $uploads = __DIR__ . '/uploads';
    if (!is_dir($uploads)) mkdir($uploads, 0755, true);
    $filename = 'profile_' . $uid . '_' . time() . '.jpg';
    $path = $uploads . '/' . $filename;
    if (file_put_contents($path, $img) === false) {
        echo json_encode(["status" => "error", "message" => "Failed to save image"]);
        exit;
    }
    // Build public URL via get_image.php for proper CORS handling
    $scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
    $host = $_SERVER['HTTP_HOST'] ?? 'localhost';
    $base_path = rtrim(dirname($_SERVER['PHP_SELF']), '/');
    $photo_url = $scheme . '://' . $host . $base_path . '/get_image.php?file=' . urlencode($filename);
    $photo_url = $conn->real_escape_string($photo_url);
    $updates[] = "profile_photo='$photo_url'";
}

if (empty($updates)) {
    echo json_encode(["status" => "error", "message" => "Nothing to update"]);
    exit;
}

$sql = "UPDATE users SET " . implode(', ', $updates) . " WHERE id=$uid";
if ($conn->query($sql) === TRUE) {
    // Return the updated fields
    $resp = ["status" => "success", "message" => "Profile updated"];
    if (isset($username)) $resp['username'] = $username;
    if (isset($photo_url)) $resp['profile_photo'] = $photo_url;
    echo json_encode($resp);
} else {
    echo json_encode(["status" => "error", "message" => "DB error: " . $conn->error]);
}

$conn->close();
