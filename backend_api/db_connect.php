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

// Polyfill getallheaders() untuk nginx / InfinityFree
if (!function_exists('getallheaders')) {
    function getallheaders() {
        $headers = [];
        foreach ($_SERVER as $name => $value) {
            if (substr($name, 0, 5) === 'HTTP_') {
                $key = str_replace(' ', '-', ucwords(strtolower(str_replace('_', ' ', substr($name, 5)))));
                $headers[$key] = $value;
            }
        }
        return $headers;
    }
}

// Cache php://input agar bisa dibaca berulang kali
$GLOBALS['_raw_input'] = file_get_contents('php://input');

// Helper: baca token dari semua sumber (URL param > POST body > $_SERVER > headers)
function getToken() {
    // 1. Dari URL query parameter ?token=
    if (!empty($_GET['token'])) return trim($_GET['token']);

    // 2. Dari POST body JSON field "_token" (paling andal untuk POST di InfinityFree)
    $rawInput = $GLOBALS['_raw_input'] ?? '';
    if ($rawInput) {
        $bodyData = json_decode($rawInput, true);
        if (!empty($bodyData['_token'])) return trim($bodyData['_token']);
    }

    // 3. Dari $_SERVER['HTTP_AUTHORIZATION']
    if (!empty($_SERVER['HTTP_AUTHORIZATION'])) {
        $auth = $_SERVER['HTTP_AUTHORIZATION'];
        return trim(stripos($auth, 'Bearer ') === 0 ? substr($auth, 7) : $auth);
    }

    // 4. Dari getallheaders()
    $headers = array_change_key_case(getallheaders(), CASE_LOWER);
    if (!empty($headers['authorization'])) {
        $auth = $headers['authorization'];
        return trim(stripos($auth, 'Bearer ') === 0 ? substr($auth, 7) : $auth);
    }
    if (!empty($headers['x-api-token'])) return trim($headers['x-api-token']);
    return null;
}
