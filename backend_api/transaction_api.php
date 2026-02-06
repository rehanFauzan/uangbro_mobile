<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, DELETE, OPTIONS");
// Allow Authorization used by clients and X-API-Token for backwards compatibility
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-API-Token");

include 'db_connect.php';

$method = $_SERVER['REQUEST_METHOD'];

// Handle CORS Pre-flight request
if ($method == 'OPTIONS') {
    http_response_code(200);
    exit();
}

switch ($method) {
    case 'GET':
        // Authenticate by token (case-insensitive header lookup)
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

        $user_id = null;
        if ($token) {
            $t = $conn->real_escape_string($token);
            $uSql = "SELECT id FROM users WHERE api_token='$t' LIMIT 1";
            $uRes = $conn->query($uSql);
            if ($uRes && $uRes->num_rows > 0) {
                $uRow = $uRes->fetch_assoc();
                $user_id = intval($uRow['id']);
            }
        }

        // If authenticated, return user's transactions plus any legacy (user_id IS NULL) so user can claim them.
        if ($user_id !== null) {
            $sql = "SELECT * FROM transactions WHERE user_id = $user_id OR user_id IS NULL ORDER BY date DESC";
        } else {
            // unauthenticated: return only legacy (public) transactions
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
        // Add new transaction or update existing one
        $input = file_get_contents("php://input");
        $data = json_decode($input, true);

        // If JSON decode fails, try form data
        if (!$data) {
            $data = $_POST;
        }

        if (isset($data['id']) && isset($data['amount']) && isset($data['type']) && isset($data['category']) && isset($data['date'])) {
            // Authenticate (case-insensitive header lookup)
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

            $user_id = null;
            if ($token) {
                $t = $conn->real_escape_string($token);
                $uSql = "SELECT id FROM users WHERE api_token='$t' LIMIT 1";
                $uRes = $conn->query($uSql);
                if ($uRes && $uRes->num_rows > 0) {
                    $uRow = $uRes->fetch_assoc();
                    $user_id = intval($uRow['id']);
                }
            }

            $id = $conn->real_escape_string($data['id']);
            $type = $conn->real_escape_string($data['type']);
            $amount = floatval($data['amount']);
            $category = $conn->real_escape_string($data['category']);
            $description = isset($data['description']) ? $conn->real_escape_string($data['description']) : '';
            $date = $conn->real_escape_string($data['date']);

            // Check if transaction with this ID already exists
            $checkSql = "SELECT id, user_id FROM transactions WHERE id='$id' LIMIT 1";
            $checkResult = $conn->query($checkSql);

            if ($checkResult && $checkResult->num_rows > 0) {
                $existing = $checkResult->fetch_assoc();
                // Only allow update if transaction belongs to this user or is legacy (user_id IS NULL) and user authenticated
                if ($existing['user_id'] === null || $existing['user_id'] === '') {
                    // legacy entry: allow update only if user authenticated (we will set user_id)
                    if ($user_id === null) {
                        echo json_encode(array("message" => "Unauthorized to update legacy transaction. Login required.", "status" => "error"));
                        break;
                    }
                    $sql = "UPDATE transactions SET type='$type', amount=$amount, category='$category', description='$description', date='$date', user_id=$user_id WHERE id='$id'";
                } else {
                    // has owner; allow only owner to update
                    if ($user_id === null || intval($existing['user_id']) !== $user_id) {
                        echo json_encode(array("message" => "Unauthorized", "status" => "error"));
                        break;
                    }
                    $sql = "UPDATE transactions SET type='$type', amount=$amount, category='$category', description='$description', date='$date' WHERE id='$id'";
                }

                if ($conn->query($sql) === TRUE) {
                    echo json_encode(array("message" => "Transaction berhasil diupdate", "status" => "success", "id" => $id));
                } else {
                    echo json_encode(array("message" => "Error updating: " . $conn->error, "status" => "error"));
                }
            } else {
                // Insert new: require authentication to attribute to a user (or leave NULL if unauthenticated)
                $user_part = ($user_id !== null) ? ", user_id=$user_id" : "";
                $sql = "INSERT INTO transactions (id, type, amount, category, description, date" . ($user_id !== null ? ", user_id" : "") . ") 
                        VALUES ('$id', '$type', $amount, '$category', '$description', '$date'" . ($user_id !== null ? ", $user_id" : "") . ")";

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

            // authenticate (case-insensitive header lookup)
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

            $user_id = null;
            if ($token) {
                $t = $conn->real_escape_string($token);
                $uSql = "SELECT id FROM users WHERE api_token='$t' LIMIT 1";
                $uRes = $conn->query($uSql);
                if ($uRes && $uRes->num_rows > 0) {
                    $uRow = $uRes->fetch_assoc();
                    $user_id = intval($uRow['id']);
                }
            }

            // Check ownership
            $checkSql = "SELECT user_id FROM transactions WHERE id='$id' LIMIT 1";
            $checkRes = $conn->query($checkSql);
            if ($checkRes && $checkRes->num_rows > 0) {
                $row = $checkRes->fetch_assoc();
                $owner = $row['user_id'];
                if ($owner !== null && $owner !== '') {
                    if ($user_id === null || intval($owner) !== $user_id) {
                        echo json_encode(array("message" => "Unauthorized to delete this transaction", "status" => "error"));
                        break;
                    }
                } else {
                    // legacy: only allow delete if authenticated
                    if ($user_id === null) {
                        echo json_encode(array("message" => "Login required to delete legacy transaction", "status" => "error"));
                        break;
                    }
                }
            }

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
