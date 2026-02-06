<?php

/**
 * Safe migration: add `profile_photo` column to `users` table if it doesn't exist.
 * Run from project root or backend_api directory:
 * php migrate_add_profile_photo.php
 */
include 'db_connect.php';

$col = 'profile_photo';
$check = $conn->query("SHOW COLUMNS FROM users LIKE '$col'");
if ($check && $check->num_rows > 0) {
    echo "Column '$col' already exists.\n";
    $conn->close();
    exit(0);
}

$sql = "ALTER TABLE users ADD COLUMN $col VARCHAR(1024) DEFAULT NULL";
if ($conn->query($sql) === TRUE) {
    echo "Column '$col' added successfully.\n";
} else {
    echo "Failed to add column '$col': " . $conn->error . "\n";
}

$conn->close();
