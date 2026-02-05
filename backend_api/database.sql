CREATE DATABASE IF NOT EXISTS uangbro_db;

USE uangbro_db;

CREATE TABLE IF NOT EXISTS transactions (
    id VARCHAR(50) PRIMARY KEY,
    type VARCHAR(10) NOT NULL,
    amount DECIMAL(15, 2) NOT NULL,
    category VARCHAR(50) NOT NULL,
    description TEXT,
    date DATETIME NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
