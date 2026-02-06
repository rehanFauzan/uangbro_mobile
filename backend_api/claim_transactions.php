<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
// Allow Authorization header for token-based auth and X-API-Token for compatibility
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-API-Token");

include 'db_connect.php';

$method = $_SERVER['REQUEST_METHOD'];
if ($method == 'OPTIONS') {
    http_response_code(200);
    exit();
}

$input = file_get_contents('php://input');
$data = json_decode($input, true) ?: $_POST;

// Expecting { ids: ["id1","id2"] }
if (!isset($data['ids']) || !is_array($data['ids'])) {
    echo json_encode(["status" => "error", "message" => "ids array required"]);
    exit;
}

// Authenticate (case-insensitive header lookup)
$rawHeaders = getallheaders();
$headers = array_change_key_case($rawHeaders, CASE_LOWER);
$token = null;
if (isset($headers['authorization'])) {
    $auth = $headers['authorization'];
    if (stripos($auth, 'Bearer ') === 0) {
        $token = substr($auth, 7);
    } else {
        $token = $auth;
    }
}
if (!$token && isset($headers['x-api-token'])) {
    $token = $headers['x-api-token'];
}

if (!$token) {
    echo json_encode(["status" => "error", "message" => "Unauthorized"]);
    exit;
}

$t = $conn->real_escape_string($token);
$uSql = "SELECT id FROM users WHERE api_token='$t' LIMIT 1";
$uRes = $conn->query($uSql);
if (!$uRes || $uRes->num_rows === 0) {
    echo json_encode(["status" => "error", "message" => "Invalid token"]);
    exit;
}
$uRow = $uRes->fetch_assoc();
$user_id = intval($uRow['id']);

// Build safe list of ids
$ids = array_map(function ($v) use ($conn) {
    return "'" . $conn->real_escape_string($v) . "'";
}, $data['ids']);
$idList = implode(',', $ids);

// Update only those with user_id IS NULL
$sql = "UPDATE transactions SET user_id=$user_id WHERE id IN ($idList) AND (user_id IS NULL OR user_id='')";
if ($conn->query($sql) === TRUE) {
    echo json_encode(["status" => "success", "message" => "Transactions claimed"]);
} else {
    echo json_encode(["status" => "error", "message" => "DB error: " . $conn->error]);
}

$conn->close();
