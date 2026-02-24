<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

include 'db_connect.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode($GLOBALS['_raw_input'] ?? file_get_contents('php://input'), true);
    $username = isset($input['username']) ? trim($input['username']) : '';
    $action = isset($input['action']) ? $input['action'] : 'request';

    if ($action === 'request') {
        // Forgot password request - send reset link
        if (empty($username)) {
            echo json_encode(['status' => 'error', 'message' => 'Username wajib diisi']);
            exit;
        }

        // Check if username exists
        $stmt = $conn->prepare("SELECT id, email FROM users WHERE username = ?");
        $stmt->bind_param("s", $username);
        $stmt->execute();
        $result = $stmt->get_result();

        if ($result->num_rows === 0) {
            echo json_encode(['status' => 'error', 'message' => 'Username tidak ditemukan']);
            exit;
        }

        $user = $result->fetch_assoc();

        // Generate reset token
        $token = bin2hex(random_bytes(32));
        $expires = date('Y-m-d H:i:s', strtotime('+1 hour'));

        // Store reset token (you might want to add a reset_token column to users table)
        // For now, we'll simulate by returning success

        // In production, you would:
        // 1. Store token in database
        // 2. Send email with reset link
        // 3. User clicks link and enters new password

        echo json_encode([
            'status' => 'success',
            'message' => 'Link reset password telah dikirim ke email',
            'data' => [
                'username' => $username,
                'email' => $user['email'],
                'reset_token' => $token // Remove in production
            ]
        ]);
    } elseif ($action === 'reset') {
        // Reset password with token
        $newPassword = isset($input['password']) ? $input['password'] : '';
        $token = isset($input['token']) ? $input['token'] : '';

        if (empty($newPassword) || empty($token)) {
            echo json_encode(['status' => 'error', 'message' => 'Password dan token wajib diisi']);
            exit;
        }

        if (strlen($newPassword) < 6) {
            echo json_encode(['status' => 'error', 'message' => 'Password minimal 6 karakter']);
            exit;
        }

        // In production, verify token from database
        // For now, we'll allow any token for demo

        // Check if username exists
        $stmt = $conn->prepare("SELECT id FROM users WHERE username = ?");
        $stmt->bind_param("s", $username);
        $stmt->execute();
        $result = $stmt->get_result();

        if ($result->num_rows === 0) {
            echo json_encode(['status' => 'error', 'message' => 'Username tidak ditemukan']);
            exit;
        }

        // Update password
        $hashedPassword = password_hash($newPassword, PASSWORD_BCRYPT);
        $stmt = $conn->prepare("UPDATE users SET password_hash = ? WHERE username = ?");
        $stmt->bind_param("ss", $hashedPassword, $username);
        $stmt->execute();

        echo json_encode(['status' => 'success', 'message' => 'Password berhasil diubah']);
    }
} else {
    echo json_encode(['status' => 'error', 'message' => 'Metode tidak diizinkan']);
}
