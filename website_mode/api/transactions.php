<?php
session_start();
header('Content-Type: application/json; charset=utf-8');

$dataDir = __DIR__ . '/../data';
$txFile = $dataDir . '/transactions.json';
if (!file_exists($dataDir)) mkdir($dataDir, 0755, true);
if (!file_exists($txFile)) file_put_contents($txFile, json_encode([]));

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

if ($method === 'GET') {
    $data = read_json($txFile);
    // optional: return only transactions for current user OR global (legacy)
    if (isset($_SESSION['user_id'])) {
        // return transactions that have user_id == session OR user_id == null (legacy)
        // For clarity, return all with those belonging to user or unclaimed
        $out = array_values(array_filter($data, function ($t) {
            return empty($t['user_id']) || $t['user_id'] === $_SESSION['user_id'];
        }));
        echo json_encode($out);
        exit;
    }
    // anonymous: return only unclaimed
    $out = array_values(array_filter($data, function ($t) {
        return empty($t['user_id']);
    }));
    echo json_encode($out);
    exit;
}

$input = json_decode(file_get_contents('php://input'), true);

if ($method === 'POST') {
    // If not logged in, create a transaction without user_id (legacy)
    $user = $_SESSION['user_id'] ?? null;
    if (!$input) {
        http_response_code(400);
        echo json_encode(['error' => 'Invalid JSON']);
        exit;
    }
    $data = read_json($txFile);
    $id = bin2hex(random_bytes(8));
    $new = [
        'id' => $id,
        'type' => $input['type'] ?? 'expense',
        'amount' => isset($input['amount']) ? floatval($input['amount']) : 0,
        'category' => $input['category'] ?? '',
        'description' => $input['description'] ?? '',
        'date' => isset($input['date']) ? $input['date'] : date('c'),
        'user_id' => $user,
        'created_at' => date('c')
    ];
    $data[] = $new;
    if (write_json($txFile, $data)) {
        http_response_code(201);
        echo json_encode($new);
    } else {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to write']);
    }
    exit;
}

if ($method === 'DELETE') {
    $id = $_GET['id'] ?? null;
    if (!$id) {
        http_response_code(400);
        echo json_encode(['error' => 'id required']);
        exit;
    }
    $data = read_json($txFile);
    $found = false;
    foreach ($data as $i => $t) {
        if ($t['id'] === $id) {
            $found = true; // only allow delete if owner or unclaimed
            if (!empty($t['user_id']) && (!isset($_SESSION['user_id']) || $_SESSION['user_id'] !== $t['user_id'])) {
                http_response_code(403);
                echo json_encode(['error' => 'Not allowed']);
                exit;
            }
            array_splice($data, $i, 1);
            break;
        }
    }
    if (!$found) {
        http_response_code(404);
        echo json_encode(['error' => 'Not found']);
        exit;
    }
    if (write_json($txFile, $data)) echo json_encode(['ok' => true]);
    else {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to write']);
    }
    exit;
}

http_response_code(405);
echo json_encode(['error' => 'Method not allowed']);
