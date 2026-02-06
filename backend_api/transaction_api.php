<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-API-Token");

include 'db_connect.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method == 'OPTIONS') {
    http_response_code(200);
    exit();
}

function getAuthUserId($conn) {
    $rawHeaders = getallheaders();
    $headers = array_change_key_case($rawHeaders, CASE_LOWER);
    $token = null;
    
    if (isset($headers['authorization'])) {
        $auth = $headers['authorization'];
        if (stripos($auth, 'Bearer ') === 0) {
            $token = substr($auth, 7);
        } else {
            $token = $auth;
        }
    }
    if (!$token && isset($headers['x-api-token'])) {
        $token = $headers['x-api-token'];
    }

    if ($token) {
        $t = $conn->real_escape_string($token);
        $uSql = "SELECT id FROM users WHERE api_token='$t' LIMIT 1";
        $uRes = $conn->query($uSql);
        if ($uRes && $uRes->num_rows > 0) {
            $uRow = $uRes->fetch_assoc();
            return intval($uRow['id']);
        }
    }
    return null;
}

switch ($method) {
    case 'GET':
        $user_id = getAuthUserId($conn);

        if ($user_id !== null) {
            $sql = "SELECT * FROM transactions WHERE user_id = $user_id OR user_id IS NULL ORDER BY date DESC";
        } else {
            $sql = "SELECT * FROM transactions WHERE user_id IS NULL ORDER BY date DESC";
        }

        $result = $conn->query($sql);
        $transactions = array();
        if ($result && $result->num_rows > 0) {
            while ($row = $result->fetch_assoc()) {
                $transactions[] = $row;
            }
        }
        echo json_encode($transactions);
        break;

    case 'POST':
        $input = file_get_contents("php://input");
        $data = json_decode($input, true);
        
        if (!$data) {
            $data = $_POST;
        }

        if (isset($data['id']) && isset($data['amount']) && isset($data['type']) && isset($data['category']) && isset($data['date'])) {
            $user_id = getAuthUserId($conn);

            $id = $conn->real_escape_string($data['id']);
            $type = $conn->real_escape_string($data['type']);
            $amount = floatval($data['amount']);
            $category = $conn->real_escape_string($data['category']);
            $description = isset($data['description']) ? $conn->real_escape_string($data['description']) : '';
            $date = $conn->real_escape_string($data['date']);

            $checkSql = "SELECT id, user_id FROM transactions WHERE id='$id' LIMIT 1";
            $checkResult = $conn->query($checkSql);

            if ($checkResult && $checkResult->num_rows > 0) {
                $existing = $checkResult->fetch_assoc();
                if ($existing['user_id'] === null || $existing['user_id'] === '') {
                    if ($user_id === null) {
                        echo json_encode(array("message" => "Login required", "status" => "error"));
                        break;
                    }
                    $sql = "UPDATE transactions SET type='$type', amount=$amount, category='$category', description='$description', date='$date', user_id=$user_id WHERE id='$id'";
                } else {
                    if ($user_id === null || intval($existing['user_id']) !== $user_id) {
                        echo json_encode(array("message" => "Unauthorized", "status" => "error"));
                        break;
                    }
                    $sql = "UPDATE transactions SET type='$type', amount=$amount, category='$category', description='$description', date='$date' WHERE id='$id'";
                }

                if ($conn->query($sql) === TRUE) {
                    echo json_encode(array("message" => "Transaction berhasil diupdate", "status" => "success", "id" => $id));
                } else {
                    echo json_encode(array("message" => "Error: " . $conn->error, "status" => "error"));
                }
            } else {
                if ($user_id !== null) {
                    $sql = "INSERT INTO transactions (id, type, amount, category, description, date, user_id) 
                            VALUES ('$id', '$type', $amount, '$category', '$description', '$date', $user_id)";
                } else {
                    $sql = "INSERT INTO transactions (id, type, amount, category, description, date) 
                            VALUES ('$id', '$type', $amount, '$category', '$description', '$date')";
                }

                if ($conn->query($sql) === TRUE) {
                    echo json_encode(array("message" => "Transaction berhasil ditambahkan", "status" => "success", "id" => $id));
                } else {
                    echo json_encode(array("message" => "Error: " . $conn->error, "status" => "error"));
                }
            }
        } else {
            echo json_encode(array("message" => "Data tidak lengkap", "status" => "error"));
        }
        break;

    case 'DELETE':
        if (isset($_GET['id'])) {
            $id = $conn->real_escape_string($_GET['id']);
            $user_id = getAuthUserId($conn);

            $checkSql = "SELECT user_id FROM transactions WHERE id='$id' LIMIT 1";
            $checkRes = $conn->query($checkSql);
            if ($checkRes && $checkRes->num_rows > 0) {
                $row = $checkRes->fetch_assoc();
                $owner = $row['user_id'];
                if ($owner !== null && $owner !== '') {
                    if ($user_id === null || intval($owner) !== $user_id) {
                        echo json_encode(array("message" => "Unauthorized", "status" => "error"));
                        break;
                    }
                } else {
                    if ($user_id === null) {
                        echo json_encode(array("message" => "Login required", "status" => "error"));
                        break;
                    }
                }
            }

            $sql = "DELETE FROM transactions WHERE id='$id'";

            if ($conn->query($sql) === TRUE) {
                echo json_encode(array("message" => "Transaction deleted", "status" => "success"));
            } else {
                echo json_encode(array("message" => "Error: " . $conn->error, "status" => "error"));
            }
        } else {
            echo json_encode(array("message" => "ID needed", "status" => "error"));
        }
        break;

    default:
        http_response_code(200);
        break;
}

$conn->close();
?>
