<?php
include 'db_connect.php';

// Test koneksi
echo "Testing database connection...\n";
if ($conn->connect_error) {
    echo "Connection failed: " . $conn->connect_error . "\n";
} else {
    echo "Connected successfully to database: " . $db . "\n";
}

// Test tabel exists
$result = $conn->query("SHOW TABLES LIKE 'transactions'");
if ($result->num_rows > 0) {
    echo "Table 'transactions' exists\n";
} else {
    echo "Table 'transactions' does not exist\n";
    // Create table
    $sql = "CREATE TABLE transactions (
        id VARCHAR(255) PRIMARY KEY,
        type VARCHAR(50) NOT NULL,
        amount DECIMAL(15,2) NOT NULL,
        category VARCHAR(100) NOT NULL,
        description TEXT,
        date DATE NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )";
    
    if ($conn->query($sql) === TRUE) {
        echo "Table 'transactions' created successfully\n";
    } else {
        echo "Error creating table: " . $conn->error . "\n";
    }
}

// Test insert
$test_data = array(
    'id' => 'TEST' . time(),
    'type' => 'expense',
    'amount' => 10000,
    'category' => 'Test',
    'description' => 'Test transaction',
    'date' => date('Y-m-d')
);

$sql = "INSERT INTO transactions (id, type, amount, category, description, date) 
        VALUES ('{$test_data['id']}', '{$test_data['type']}', {$test_data['amount']}, '{$test_data['category']}', '{$test_data['description']}', '{$test_data['date']}')";

if ($conn->query($sql) === TRUE) {
    echo "Test transaction inserted successfully\n";
} else {
    echo "Error inserting test transaction: " . $conn->error . "\n";
}

$conn->close();
?>