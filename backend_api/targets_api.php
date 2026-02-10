<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE');
header('Access-Control-Allow-Headers: Content-Type');

// Database connection - use same settings as other API files
$host = '127.0.0.1';
$port = 3306;
$dbname = 'uangbro_db';
$username = 'root';
$password = 'root';
$socket = '/Applications/MAMP/tmp/mysql/mysql.sock';

try {
    $pdo = new PDO("mysql:host=$host;port=$port;dbname=$dbname;unix_socket=$socket", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
    echo json_encode(['success' => false, 'message' => 'Database connection failed: ' . $e->getMessage()]);
    exit;
}

// Get request method
$method = $_SERVER['REQUEST_METHOD'];

// Get JSON input for POST/PUT
$input = [];
if ($method == 'POST' || $method == 'PUT') {
    $input = json_decode(file_get_contents('php://input'), true);
}

// Get user_id from GET or JSON body
$user_id = isset($_GET['user_id']) ? $_GET['user_id'] : (isset($input['user_id']) ? $input['user_id'] : null);

if (!$user_id) {
    echo json_encode(['success' => false, 'message' => 'user_id is required']);
    exit;
}

// GET - Fetch all targets for user
if ($method == 'GET') {
    try {
        $stmt = $pdo->prepare("SELECT * FROM targets WHERE user_id = ? ORDER BY deadline ASC");
        $stmt->execute([$user_id]);
        $targets = $stmt->fetchAll(PDO::FETCH_ASSOC);

        echo json_encode(['success' => true, 'data' => $targets]);
    } catch (PDOException $e) {
        echo json_encode(['success' => false, 'message' => 'Failed to fetch targets: ' . $e->getMessage()]);
    }
    exit;
}

// POST - Create new target
if ($method == 'POST') {
    $name = isset($input['name']) ? $input['name'] : null;
    $target_amount = isset($input['target_amount']) ? floatval($input['target_amount']) : 0;
    $deadline = isset($input['deadline']) ? $input['deadline'] : null;

    if (!$name || !$target_amount || !$deadline) {
        echo json_encode(['success' => false, 'message' => 'name, target_amount, and deadline are required']);
        exit;
    }

    try {
        $stmt = $pdo->prepare("INSERT INTO targets (user_id, name, target_amount, current_progress, deadline, created_at, is_completed) VALUES (?, ?, ?, 0, ?, NOW(), 0)");
        $stmt->execute([$user_id, $name, $target_amount, $deadline]);

        $target_id = $pdo->lastInsertId();

        echo json_encode(['success' => true, 'message' => 'Target created successfully', 'target_id' => $target_id]);
    } catch (PDOException $e) {
        echo json_encode(['success' => false, 'message' => 'Failed to create target: ' . $e->getMessage()]);
    }
    exit;
}

// PUT - Update existing target
if ($method == 'PUT') {
    $target_id = isset($_GET['target_id']) ? $_GET['target_id'] : (isset($input['target_id']) ? $input['target_id'] : null);

    if (!$target_id) {
        echo json_encode(['success' => false, 'message' => 'target_id is required']);
        exit;
    }

    // Build update query
    $updates = [];
    $params = [];

    if (isset($input['name'])) {
        $updates[] = 'name = ?';
        $params[] = $input['name'];
    }
    if (isset($input['target_amount'])) {
        $updates[] = 'target_amount = ?';
        $params[] = floatval($input['target_amount']);
    }
    if (isset($input['deadline'])) {
        $updates[] = 'deadline = ?';
        $params[] = $input['deadline'];
    }
    if (isset($input['current_progress'])) {
        $updates[] = 'current_progress = ?';
        $params[] = floatval($input['current_progress']);
    }
    if (isset($input['is_completed'])) {
        $updates[] = 'is_completed = ?';
        $params[] = $input['is_completed'] ? 1 : 0;
    }

    if (empty($updates)) {
        echo json_encode(['success' => false, 'message' => 'No fields to update']);
        exit;
    }

    $params[] = $target_id;
    $params[] = $user_id;

    try {
        $sql = "UPDATE targets SET " . implode(', ', $updates) . " WHERE id = ? AND user_id = ?";
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);

        echo json_encode(['success' => true, 'message' => 'Target updated successfully']);
    } catch (PDOException $e) {
        echo json_encode(['success' => false, 'message' => 'Failed to update target: ' . $e->getMessage()]);
    }
    exit;
}

// DELETE - Delete target
if ($method == 'DELETE') {
    $target_id = isset($_GET['target_id']) ? $_GET['target_id'] : null;

    if (!$target_id) {
        echo json_encode(['success' => false, 'message' => 'target_id is required']);
        exit;
    }

    try {
        $stmt = $pdo->prepare("DELETE FROM targets WHERE id = ? AND user_id = ?");
        $stmt->execute([$target_id, $user_id]);

        if ($stmt->rowCount() > 0) {
            echo json_encode(['success' => true, 'message' => 'Target deleted successfully']);
        } else {
            echo json_encode(['success' => false, 'message' => 'Target not found']);
        }
    } catch (PDOException $e) {
        echo json_encode(['success' => false, 'message' => 'Failed to delete target: ' . $e->getMessage()]);
    }
    exit;
}

echo json_encode(['success' => false, 'message' => 'Invalid request method']);
