<?php
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Process the form submission
    include 'db_connect.php';
    
    $id = 'TXN' . time();
    $type = 'expense';
    $amount = 25000;
    $category = 'Food';
    $description = 'Test dari form';
    $date = date('Y-m-d');
    
    $sql = "INSERT INTO transactions (id, type, amount, category, description, date) 
            VALUES ('$id', '$type', $amount, '$category', '$description', '$date')";
    
    if ($conn->query($sql) === TRUE) {
        $message = "✅ Transaction berhasil ditambahkan dengan ID: $id";
    } else {
        $message = "❌ Error: " . $conn->error;
    }
    $conn->close();
}
?>
<!DOCTYPE html>
<html>
<head>
    <title>Direct Test</title>
</head>
<body>
    <h2>Direct Database Test</h2>
    
    <?php if (isset($message)): ?>
        <div style="padding: 10px; margin: 10px 0; border: 1px solid #ccc; background: #f9f9f9;">
            <?php echo $message; ?>
        </div>
    <?php endif; ?>
    
    <form method="POST">
        <button type="submit">Add Test Transaction</button>
    </form>
    
    <hr>
    
    <h3>Current Transactions:</h3>
    <?php
    include 'db_connect.php';
    $result = $conn->query("SELECT * FROM transactions ORDER BY date DESC LIMIT 5");
    if ($result && $result->num_rows > 0) {
        echo "<table border='1'><tr><th>ID</th><th>Type</th><th>Amount</th><th>Category</th><th>Date</th></tr>";
        while($row = $result->fetch_assoc()) {
            echo "<tr><td>{$row['id']}</td><td>{$row['type']}</td><td>{$row['amount']}</td><td>{$row['category']}</td><td>{$row['date']}</td></tr>";
        }
        echo "</table>";
    } else {
        echo "No transactions found.";
    }
    $conn->close();
    ?>
</body>
</html>