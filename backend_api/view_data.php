<?php
include 'db_connect.php';

echo "<h2>Users:</h2>";
$users = $conn->query("SELECT id, username, email FROM users");
if ($users && $users->num_rows > 0) {
    echo "<table border='1'><tr><th>ID</th><th>Username</th><th>Email</th></tr>";
    while($row = $users->fetch_assoc()) {
        echo "<tr><td>{$row['id']}</td><td>{$row['username']}</td><td>{$row['email']}</td></tr>";
    }
    echo "</table>";
} else {
    echo "No users found";
}

echo "<h2>Transactions:</h2>";
$trans = $conn->query("SELECT id, type, amount, category, date, user_id FROM transactions ORDER BY date DESC LIMIT 10");
if ($trans && $trans->num_rows > 0) {
    echo "<table border='1'><tr><th>ID</th><th>Type</th><th>Amount</th><th>Category</th><th>Date</th><th>User ID</th></tr>";
    while($row = $trans->fetch_assoc()) {
        $uid = $row['user_id'] ?? 'NULL';
        echo "<tr><td>{$row['id']}</td><td>{$row['type']}</td><td>{$row['amount']}</td><td>{$row['category']}</td><td>{$row['date']}</td><td>$uid</td></tr>";
    }
    echo "</table>";
} else {
    echo "No transactions found";
}

$conn->close();
?>
