<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST');
header('Access-Control-Allow-Headers: Content-Type');

include 'db_connect.php';

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    // Export transactions to CSV
    $userId = isset($_GET['user_id']) ? $_GET['user_id'] : '';

    if (empty($userId)) {
        echo json_encode(['status' => 'error', 'message' => 'User ID wajib diisi']);
        exit;
    }

    // Get transactions
    $stmt = $conn->prepare("
        SELECT t.id, t.type, t.amount, t.description, t.date, 
               c.name as category, t.is_recurring, t.recurring_interval
        FROM transactions t
        LEFT JOIN categories c ON t.category_id = c.id
        WHERE t.user_id = ?
        ORDER BY t.date DESC
    ");
    $stmt->bind_param("s", $userId);
    $stmt->execute();
    $result = $stmt->get_result();

    $transactions = [];
    while ($row = $result->fetch_assoc()) {
        $transactions[] = $row;
    }

    if (empty($transactions)) {
        echo json_encode(['status' => 'error', 'message' => 'Tidak ada transaksi untuk diexport']);
        exit;
    }

    // Generate CSV
    $filename = "uangbro_export_" . date('Y-m-d_H-i-s') . ".csv";

    header('Content-Type: text/csv');
    header('Content-Disposition: attachment; filename="' . $filename . '"');
    header('Pragma: no-cache');
    header('Expires: 0');

    $output = fopen('php://output', 'w');

    // CSV Header
    fputcsv($output, ['ID', 'Tipe', 'Jumlah', 'Deskripsi', 'Tanggal', 'Kategori', 'Berulang', 'Interval']);

    // CSV Data
    foreach ($transactions as $t) {
        fputcsv($output, [
            $t['id'],
            $t['type'],
            $t['amount'],
            $t['description'],
            $t['date'],
            $t['category'],
            $t['is_recurring'] ? 'Ya' : 'Tidak',
            $t['recurring_interval'] ?? '-'
        ]);
    }

    fclose($output);
    exit;
} elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Import transactions from CSV
    $input = json_decode(file_get_contents('php://input'), true);
    $userId = isset($input['user_id']) ? $input['user_id'] : '';
    $transactions = isset($input['transactions']) ? $input['transactions'] : [];

    if (empty($userId)) {
        echo json_encode(['status' => 'error', 'message' => 'User ID wajib diisi']);
        exit;
    }

    if (empty($transactions)) {
        echo json_encode(['status' => 'error', 'message' => 'Data transaksi kosong']);
        exit;
    }

    $imported = 0;
    $errors = [];

    foreach ($transactions as $t) {
        // Skip if amount is not numeric
        if (!is_numeric($t['amount'])) {
            $errors[] = "Transaksi {$t['description']}: jumlah tidak valid";
            continue;
        }

        // Get category ID
        $categoryId = null;
        if (!empty($t['category'])) {
            $stmt = $conn->prepare("SELECT id FROM categories WHERE name = ? LIMIT 1");
            $stmt->bind_param("s", $t['category']);
            $stmt->execute();
            $catResult = $stmt->get_result();
            if ($catRow = $catResult->fetch_assoc()) {
                $categoryId = $catRow['id'];
            }
        }

        // Insert transaction
        $type = isset($t['type']) ? $t['type'] : 'expense';
        $description = isset($t['description']) ? $t['description'] : 'Imported';
        $amount = floatval($t['amount']);
        $date = isset($t['date']) ? $t['date'] : date('Y-m-d');
        $isRecurring = isset($t['is_recurring']) && $t['is_recurring'] == 'Ya' ? 1 : 0;
        $recurringInterval = isset($t['recurring_interval']) ? $t['recurring_interval'] : null;

        $stmt = $conn->prepare("
            INSERT INTO transactions (user_id, type, amount, description, date, category_id, is_recurring, recurring_interval, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW())
        ");
        $stmt->bind_param("ssdsss", $userId, $type, $amount, $description, $date, $categoryId, $isRecurring, $recurringInterval);

        if ($stmt->execute()) {
            $imported++;
        } else {
            $errors[] = "Gagal import {$description}: " . $stmt->error;
        }
    }

    echo json_encode([
        'status' => 'success',
        'message' => "Berhasil import $imported transaksi",
        'imported' => $imported,
        'errors' => $errors
    ]);
} else {
    echo json_encode(['status' => 'error', 'message' => 'Metode tidak diizinkan']);
}
