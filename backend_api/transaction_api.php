<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

include 'db_connect.php';

$method = $_SERVER['REQUEST_METHOD'];

// Handle CORS Pre-flight request
if ($method == 'OPTIONS') {
    http_response_code(200);
    exit();
}

switch ($method) {
    case 'GET':
        // Get all transactions
        $sql = "SELECT * FROM transactions ORDER BY date DESC";
        $result = $conn->query($sql);
        
        $transactions = array();
        if ($result->num_rows > 0) {
            while($row = $result->fetch_assoc()) {
                $transactions[] = $row;
            }
        }
        echo json_encode($transactions);
        break;

    case 'POST':
        // Add new transaction
        $data = json_decode(file_get_contents("php://input"), true);
        
        if(isset($data['id']) && isset($data['amount'])) {
            $id = $conn->real_escape_string($data['id']);
            $type = $conn->real_escape_string($data['type']);
            $amount = $data['amount'];
            $category = $conn->real_escape_string($data['category']);
            $description = $conn->real_escape_string($data['description']);
            $date = $conn->real_escape_string($data['date']);

            $sql = "INSERT INTO transactions (id, type, amount, category, description, date) 
                    VALUES ('$id', '$type', '$amount', '$category', '$description', '$date')";

            if ($conn->query($sql) === TRUE) {
                echo json_encode(array("message" => "Transaction created", "status" => "success"));
            } else {
                echo json_encode(array("message" => "Error: " . $sql . "<br>" . $conn->error, "status" => "error"));
            }
        } else {
            echo json_encode(array("message" => "Incomplete data", "status" => "error"));
        }
        break;

    case 'DELETE':
        // Delete transaction
        if (isset($_GET['id'])) {
            $id = $conn->real_escape_string($_GET['id']);
            $sql = "DELETE FROM transactions WHERE id='$id'";

            if ($conn->query($sql) === TRUE) {
                echo json_encode(array("message" => "Transaction deleted", "status" => "success"));
            } else {
                echo json_encode(array("message" => "Error deleting record: " . $conn->error, "status" => "error"));
            }
        } else {
            echo json_encode(array("message" => "ID needed", "status" => "error"));
        }
        break;
        
    default:
        // OPTIONS or other methods
        http_response_code(200);
        break;
}

$conn->close();
?>
