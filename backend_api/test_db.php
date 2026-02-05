<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");

$host = "localhost";
$user = "root";
$pass = "root";
$db = "uangbro_db";

// Test connection
$conn = new mysqli($host, $user, $pass, $db);

if ($conn->connect_error) {
    echo json_encode([
        "status" => "error",
        "message" => "Connection failed: " . $conn->connect_error,
        "config" => [
            "host" => $host,
            "user" => $user,
            "database" => $db
        ]
    ]);
} else {
    // Test if table exists
    $result = $conn->query("SHOW TABLES LIKE 'transactions'");
    $table_exists = $result->num_rows > 0;
    
    // Test insert
    $test_id = "TEST_" . time();
    $sql = "INSERT INTO transactions (id, type, amount, category, description, date) 
            VALUES ('$test_id', 'expense', 10000, 'Test', 'Test transaction', '2024-01-15')";
    
    $insert_success = $conn->query($sql);
    $insert_error = $conn->error;
    
    // Count records
    $count_result = $conn->query("SELECT COUNT(*) as total FROM transactions");
    $total_records = $count_result ? $count_result->fetch_assoc()['total'] : 0;
    
    echo json_encode([
        "status" => "success",
        "message" => "Database connected successfully",
        "table_exists" => $table_exists,
        "insert_test" => $insert_success,
        "insert_error" => $insert_error,
        "total_records" => $total_records,
        "test_id" => $test_id
    ]);
}

$conn->close();
?>