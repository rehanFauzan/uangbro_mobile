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
            while ($row = $result->fetch_assoc()) {
                $transactions[] = $row;
            }
        }
        echo json_encode($transactions);
        break;

    case 'POST':
        // Add new transaction or update existing one
        $input = file_get_contents("php://input");
        $data = json_decode($input, true);

        // If JSON decode fails, try form data
        if (!$data) {
            $data = $_POST;
        }

        if (isset($data['id']) && isset($data['amount']) && isset($data['type']) && isset($data['category']) && isset($data['date'])) {
            $id = $conn->real_escape_string($data['id']);
            $type = $conn->real_escape_string($data['type']);
            $amount = floatval($data['amount']);
            $category = $conn->real_escape_string($data['category']);
            $description = isset($data['description']) ? $conn->real_escape_string($data['description']) : '';
            $date = $conn->real_escape_string($data['date']);

            // Check if transaction with this ID already exists
            $checkSql = "SELECT id FROM transactions WHERE id='$id' LIMIT 1";
            $checkResult = $conn->query($checkSql);

            if ($checkResult && $checkResult->num_rows > 0) {
                // Update existing
                $sql = "UPDATE transactions SET type='$type', amount=$amount, category='$category', description='$description', date='$date' WHERE id='$id'";
                if ($conn->query($sql) === TRUE) {
                    echo json_encode(array("message" => "Transaction berhasil diupdate", "status" => "success", "id" => $id));
                } else {
                    echo json_encode(array("message" => "Error updating: " . $conn->error, "status" => "error"));
                }
            } else {
                // Insert new
                $sql = "INSERT INTO transactions (id, type, amount, category, description, date) 
                        VALUES ('$id', '$type', $amount, '$category', '$description', '$date')";

                if ($conn->query($sql) === TRUE) {
                    echo json_encode(array("message" => "Transaction berhasil ditambahkan", "status" => "success", "id" => $id));
                } else {
                    echo json_encode(array("message" => "Error: " . $conn->error, "status" => "error"));
                }
            }
        } else {
            echo json_encode(array("message" => "Data tidak lengkap", "received" => $data, "status" => "error"));
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
