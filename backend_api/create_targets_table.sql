-- Create targets table for uangbro database
CREATE TABLE IF NOT EXISTS targets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    target_amount DECIMAL(15, 2) NOT NULL DEFAULT 0,
    current_progress DECIMAL(15, 2) NOT NULL DEFAULT 0,
    deadline DATETIME NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_completed TINYINT(1) NOT NULL DEFAULT 0,
    INDEX idx_user_id (user_id),
    INDEX idx_deadline (deadline)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
