<?php
header('Content-Type: application/json; charset=utf-8');

$dataFile = __DIR__ . '/../data/targets.json';

// Ensure data dir/file exists
if (!file_exists(dirname($dataFile))) {
    mkdir(dirname($dataFile), 0755, true);
}
if (!file_exists($dataFile)) {
    file_put_contents($dataFile, json_encode([]));
}

function read_data($file)
{
    $raw = file_get_contents($file);
    $arr = json_decode($raw, true);
    if (!is_array($arr)) $arr = [];
    return $arr;
}

function write_data($file, $arr)
{
    $tmp = json_encode($arr, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    // write with lock
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
    // optional id
    $data = read_data($dataFile);
    if (isset($_GET['id'])) {
        $id = $_GET['id'];
        foreach ($data as $item) if ((string)$item['id'] === (string)$id) {
            echo json_encode($item);
            exit;
        }
        http_response_code(404);
        echo json_encode(['error' => 'Not found']);
        exit;
    }
    echo json_encode($data);
    exit;
}

$input = json_decode(file_get_contents('php://input'), true);

if ($method === 'POST') {
    if (!$input) {
        http_response_code(400);
        echo json_encode(['error' => 'Invalid JSON']);
        exit;
    }
    $data = read_data($dataFile);
    // create id
    $ids = array_column($data, 'id');
    $newId = $ids ? (max($ids) + 1) : 1;
    $new = [
        'id' => $newId,
        'title' => $input['title'] ?? '',
        'amount' => isset($input['amount']) ? (float)$input['amount'] : 0,
        'due_date' => $input['due_date'] ?? null,
        'created_at' => date('c')
    ];
    $data[] = $new;
    if (write_data($dataFile, $data)) {
        http_response_code(201);
        echo json_encode($new);
    } else {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to write data']);
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
    $data = read_data($dataFile);
    $found = false;
    foreach ($data as $i => $item) {
        if ((string)$item['id'] === (string)$id) {
            $found = true;
            array_splice($data, $i, 1);
            break;
        }
    }
    if (!$found) {
        http_response_code(404);
        echo json_encode(['error' => 'Not found']);
        exit;
    }
    if (write_data($dataFile, $data)) {
        echo json_encode(['ok' => true]);
    } else {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to write data']);
    }
    exit;
}

// PUT could be added similarly; for now, only GET/POST/DELETE implemented
http_response_code(405);
echo json_encode(['error' => 'Method not allowed']);
