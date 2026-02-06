<?php
include 'db_connect.php';

// Check if user_id column exists
$result = $conn->query("SHOW COLUMNS FROM transactions LIKE 'user_id'");

if ($result->num_rows == 0) {
    // Add user_id column
    $sql = "ALTER TABLE transactions ADD COLUMN user_id INT NULL AFTER date";
    if ($conn->query($sql) === TRUE) {
        echo "Column user_id added successfully\n";
    } else {
        echo "Error adding column: " . $conn->error . "\n";
    }
} else {
    echo "Column user_id already exists\n";
}

$conn->close();
?>
