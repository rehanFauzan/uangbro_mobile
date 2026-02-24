<?php
session_start();
header('Content-Type: application/json; charset=utf-8');

$dataDir = __DIR__ . '/../data';
$usersFile = $dataDir . '/users.json';
if (!file_exists($dataDir)) mkdir($dataDir, 0755, true);
if (!file_exists($usersFile)) file_put_contents($usersFile, json_encode([]));

function read_json($file)
{
    $raw = file_get_contents($file);
    $arr = json_decode($raw, true);
    return is_array($arr) ? $arr : [];
}
function write_json($file, $arr)
{
    $tmp = json_encode($arr, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    $fp = fopen($file, 'c');
    if (!$fp) return false;
    flock($fp, LOCK_EX);
    ftruncate($fp, 0);
    fwrite($fp, $tmp);
    fflush($fp);
    flock($fp, LOCK_UN);
    fclose($fp);
    return true;
}

$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? '';

if ($method === 'GET' && empty($action)) {
    // return current user
    if (isset($_SESSION['user_id'])) {
        $users = read_json($usersFile);
        foreach ($users as $u) if ($u['id'] === $_SESSION['user_id']) {
            echo json_encode(['id' => $u['id'], 'username' => $u['username']]);
            exit;
        }
    }
    echo json_encode(new stdClass());
    exit;
}

if ($method === 'POST' && $action === 'register') {
    $input = json_decode(file_get_contents('php://input'), true);
    if (!$input || empty($input['username']) || empty($input['password'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Missing username or password']);
        exit;
    }
    $username = trim($input['username']);
    $password = $input['password'];
    $users = read_json($usersFile);
    foreach ($users as $u) if (strtolower($u['username']) === strtolower($username)) {
        http_response_code(400);
        echo json_encode(['error' => 'Username sudah dipakai']);
        exit;
    }
    $id = bin2hex(random_bytes(8));
    $users[] = ['id' => $id, 'username' => $username, 'password' => password_hash($password, PASSWORD_DEFAULT)];
    if (write_json($usersFile, $users)) {
        echo json_encode(['id' => $id, 'username' => $username]);
    } else {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to write users']);
    }
    exit;
}

if ($method === 'POST' && $action === 'login') {
    $input = json_decode(file_get_contents('php://input'), true);
    if (!$input || empty($input['username']) || empty($input['password'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Missing username or password']);
        exit;
    }
    $username = trim($input['username']);
    $password = $input['password'];
    $users = read_json($usersFile);
    foreach ($users as $u) {
        if (strtolower($u['username']) === strtolower($username) && password_verify($password, $u['password'])) {
            $_SESSION['user_id'] = $u['id'];
            echo json_encode(['id' => $u['id'], 'username' => $u['username']]);
            exit;
        }
    }
    http_response_code(401);
    echo json_encode(['error' => 'Login gagal']);
    exit;
}

if ($method === 'POST' && $action === 'logout') {
    session_unset();
    session_destroy();
    echo json_encode(['ok' => true]);
    exit;
}

// Claim legacy transactions: POST?action=claim with JSON body { ids: [...] }
if ($method === 'POST' && $action === 'claim') {
    if (!isset($_SESSION['user_id'])) {
        http_response_code(401);
        echo json_encode(['error' => 'Not authenticated']);
        exit;
    }
    $input = json_decode(file_get_contents('php://input'), true);
    if (!$input || !isset($input['ids']) || !is_array($input['ids'])) {
        http_response_code(400);
        echo json_encode(['error' => 'ids required']);
        exit;
    }
    $txFile = $dataDir . '/transactions.json';
    if (!file_exists($txFile)) file_put_contents($txFile, json_encode([]));
    $tx = read_json($txFile);
    $changed = 0;
    foreach ($tx as &$t) {
        if (in_array($t['id'], $input['ids']) && (empty($t['user_id']) || $t['user_id'] === null)) {
            $t['user_id'] = $_SESSION['user_id'];
            $changed++;
        }
    }
    if (write_json($txFile, $tx)) echo json_encode(['status' => 'success', 'changed' => $changed]);
    else {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to write']);
    }
    exit;
}

http_response_code(405);
echo json_encode(['error' => 'Method not allowed']);
