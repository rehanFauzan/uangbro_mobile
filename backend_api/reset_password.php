<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

include 'db_connect.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode($GLOBALS['_raw_input'] ?? file_get_contents('php://input'), true);
    $username = isset($input['username']) ? trim($input['username']) : '';
    $newPassword = isset($input['password']) ? $input['password'] : '';

    if (empty($username) || empty($newPassword)) {
        echo json_encode(['status' => 'error', 'message' => 'Username dan password wajib diisi']);
        exit;
    }

    if (strlen($newPassword) < 6) {
        echo json_encode(['status' => 'error', 'message' => 'Password minimal 6 karakter']);
        exit;
    }

    // Check if username exists
    $stmt = $conn->prepare("SELECT id FROM users WHERE username = ?");
    $stmt->bind_param("s", $username);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows === 0) {
        echo json_encode(['status' => 'error', 'message' => 'Username tidak ditemukan']);
        exit;
    }

    // Update password (using password_hash)
    $hashedPassword = password_hash($newPassword, PASSWORD_BCRYPT);
    $stmt = $conn->prepare("UPDATE users SET password_hash = ? WHERE username = ?");
    $stmt->bind_param("ss", $hashedPassword, $username);
    $stmt->execute();

    echo json_encode(['status' => 'success', 'message' => 'Password berhasil diubah']);
} else {
    echo json_encode(['status' => 'error', 'message' => 'Metode tidak diizinkan']);
}
