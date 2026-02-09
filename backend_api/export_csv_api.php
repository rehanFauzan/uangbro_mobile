<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type');

// Disable error display to prevent HTML errors in JSON response
ini_set('display_errors', 0);
error_reporting(0);

include 'db_connect.php';

$userId = isset($_GET['user_id']) ? $_GET['user_id'] : '';

if (empty($userId)) {
    echo json_encode(['status' => 'error', 'message' => 'User ID wajib diisi']);
    exit;
}

// Check connection
if ($conn->connect_error) {
    echo json_encode(['status' => 'error', 'message' => 'Database connection failed: ' . $conn->connect_error]);
    exit;
}

// Get transactions - using the actual schema (no categories table, no is_recurring/recurring_interval)
$stmt = $conn->prepare("
    SELECT id, type, amount, category, description, date, user_id
    FROM transactions
    WHERE user_id = ?
    ORDER BY date DESC
");

if (!$stmt) {
    echo json_encode(['status' => 'error', 'message' => 'Prepare failed: ' . $conn->error]);
    exit;
}

$stmt->bind_param("s", $userId);
$stmt->execute();
$result = $stmt->get_result();

if (!$result) {
    echo json_encode(['status' => 'error', 'message' => 'Query failed: ' . $stmt->error]);
    exit;
}

$transactions = [];
while ($row = $result->fetch_assoc()) {
    $transactions[] = $row;
}

$stmt->close();

// Generate CSV content
$csvContent = "ID,Tipe,Jumlah,Deskripsi,Tanggal,Kategori\n";
foreach ($transactions as $t) {
    $csvContent .= sprintf(
        "%s,%s,%.2f,\"%s\",%s,\"%s\"\n",
        $t['id'],
        $t['type'],
        $t['amount'],
        str_replace('"', '""', $t['description'] ?? ''),
        $t['date'],
        str_replace('"', '""', $t['category'] ?? '')
    );
}

// Return as JSON with base64 encoded CSV
echo json_encode([
    'status' => 'success',
    'filename' => 'uangbro_transaksi_' . date('Y-m-d_H-i-s') . '.csv',
    'csv' => base64_encode($csvContent),
    'count' => count($transactions)
]);
