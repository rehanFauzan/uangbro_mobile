-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Host: localhost:8889
-- Waktu pembuatan: 23 Feb 2026 pada 08.40
-- Versi server: 8.0.44
-- Versi PHP: 7.4.33
-- raihanfauazan

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Basis data: `uangbro_db`
--

-- --------------------------------------------------------

--
-- Struktur dari tabel `password_resets`
--

CREATE TABLE `password_resets` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `reset_code` varchar(6) NOT NULL,
  `expires_at` datetime NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data untuk tabel `password_resets`
--

INSERT INTO `password_resets` (`id`, `user_id`, `reset_code`, `expires_at`, `created_at`) VALUES
(1, 3, '574136', '2026-02-06 10:22:27', '2026-02-06 09:22:27'),
(2, 3, '138714', '2026-02-06 10:27:47', '2026-02-06 09:27:47');

-- --------------------------------------------------------

--
-- Struktur dari tabel `savings_contributions`
--

CREATE TABLE `savings_contributions` (
  `id` varchar(36) NOT NULL,
  `goal_id` varchar(36) NOT NULL,
  `user_id` int DEFAULT NULL,
  `transaction_id` varchar(36) DEFAULT NULL,
  `amount` decimal(15,2) NOT NULL,
  `note` varchar(500) DEFAULT NULL,
  `contributed_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Struktur dari tabel `savings_goals`
--

CREATE TABLE `savings_goals` (
  `id` varchar(36) NOT NULL,
  `user_id` int DEFAULT NULL,
  `name` varchar(255) NOT NULL,
  `target_amount` decimal(15,2) NOT NULL,
  `current_amount` decimal(15,2) DEFAULT '0.00',
  `deadline` date DEFAULT NULL,
  `icon` varchar(50) DEFAULT 'savings',
  `color` varchar(20) DEFAULT '#4CAF50',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_completed` tinyint(1) DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data untuk tabel `savings_goals`
--

INSERT INTO `savings_goals` (`id`, `user_id`, `name`, `target_amount`, `current_amount`, `deadline`, `icon`, `color`, `created_at`, `updated_at`, `is_completed`) VALUES
('test_6989929f34187', 3, 'Test Goal 2026-02-09 07:54:07', 1000000.00, 0.00, NULL, 'savings', '#4CAF50', '2026-02-09 07:54:07', '2026-02-09 07:54:07', 0);

-- --------------------------------------------------------

--
-- Struktur dari tabel `targets`
--

CREATE TABLE `targets` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `target_amount` decimal(15,2) NOT NULL DEFAULT '0.00',
  `current_progress` decimal(15,2) NOT NULL DEFAULT '0.00',
  `deadline` datetime NOT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_completed` tinyint(1) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data untuk tabel `targets`
--

INSERT INTO `targets` (`id`, `user_id`, `name`, `target_amount`, `current_progress`, `deadline`, `created_at`, `is_completed`) VALUES
(1, 1, 'Test Target', 1000000.00, 0.00, '2025-12-31 00:00:00', '2026-02-10 16:22:44', 0),
(5, 3, 'flowers', 350000.00, 0.00, '2026-03-12 00:00:00', '2026-02-10 16:34:48', 0);

-- --------------------------------------------------------

--
-- Struktur dari tabel `transactions`
--

CREATE TABLE `transactions` (
  `id` varchar(255) NOT NULL,
  `type` varchar(50) NOT NULL,
  `amount` decimal(15,2) NOT NULL,
  `category` varchar(100) NOT NULL,
  `description` text,
  `date` date NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `user_id` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data untuk tabel `transactions`
--

INSERT INTO `transactions` (`id`, `type`, `amount`, `category`, `description`, `date`, `created_at`, `user_id`) VALUES
('0aef7eff-7a08-4439-8b28-2c66392926f7', 'expense', 20000.00, 'Transport', 'bensin el', '2026-02-13', '2026-02-13 04:13:48', 3),
('0ea60254-dc3a-42e9-8165-729c33daea20', 'expense', 2000.00, 'Tagihan', 'parkir', '2026-02-07', '2026-02-07 05:57:19', 3),
('10a5925f-f055-4c7f-8e70-64eaaa3add7d', 'income', 25000.00, 'Investasi', 'uang jajan', '2026-02-10', '2026-02-10 01:49:01', 3),
('1ab68d51-1ee8-404c-a719-d9f74c4965ac', 'expense', 2000.00, 'Tagihan', 'ngamen', '2026-02-10', '2026-02-10 06:55:16', 3),
('1d43cd8c-ae2e-481f-9d87-d977d49976f5', 'expense', 20000.00, 'Bensin', 'bensin', '2026-02-05', '2026-02-05 13:17:53', 3),
('2902f0e8-21d9-4d89-802e-db2528fa1c1f', 'expense', 1500.00, 'Tagihan', 'parkir', '2026-02-10', '2026-02-11 01:36:48', 3),
('2ab2cba1-e19a-49fd-ae9c-500cf3b53a7d', 'income', 40000.00, 'uang jajan', 'uang jajan', '2026-02-05', '2026-02-05 13:17:16', 3),
('3f9a70e3-e210-4f1c-a148-b42fd6c3142f', 'income', 10000.00, 'Investasi', 'nemu di tas', '2026-02-09', '2026-02-09 02:39:28', 3),
('40b28ee3-1a5f-4c97-8268-1bf8930b0ceb', 'income', 1000.00, 'Investasi', 'nemu', '2026-02-10', '2026-02-10 06:55:36', 3),
('41448a08-408e-4dae-b9a5-892c5bcfabb0', 'income', 70000.00, 'Investasi', 'uang jajan', '2026-02-23', '2026-02-23 06:45:08', 3),
('4891bde3-8218-485a-8c2d-c7d2199f659e', 'income', 30000.00, 'Investasi', 'uang jajan', '2026-02-11', '2026-02-11 01:38:15', 3),
('4ceb716f-d52d-4dbc-a373-b559157bb3a4', 'income', 25000.00, 'Transport', 'uang jajan', '2026-02-09', '2026-02-09 01:23:54', 3),
('4ea82bc4-6c3a-4fbe-ba05-97913359ef32', 'expense', 5000.00, 'Belanja', 'basreng', '2026-02-08', '2026-02-09 01:23:18', 3),
('5450c6f3-c440-4f26-800c-1c5dbc946592', 'expense', 10000.00, 'Transport', 'bensin', '2026-02-11', '2026-02-11 01:39:01', 3),
('60cf4eab-2262-4f9f-b4de-8635bef44441', 'expense', 20000.00, 'Belanja', 'jajan helga', '2026-02-12', '2026-02-12 13:22:21', 3),
('767c87d1-bef0-4202-9085-d37a92d0ba06', 'expense', 15000.00, 'Transport', 'bensin', '2026-02-12', '2026-02-12 02:54:41', 3),
('7d999bdf-8a80-4bc9-8226-e928c3674594', 'income', 25000.00, 'Transport', 'uang jajan', '2026-02-12', '2026-02-12 02:53:56', 3),
('809f5b75-049e-41f1-af65-3a80dac13cf4', 'expense', 22000.00, 'Belanja', 'makanan helga', '2026-02-07', '2026-02-07 05:56:49', 3),
('94853bd4-3f71-45a5-8e0a-1da09ec4f83d', 'expense', 20000.00, 'Bensin', 'bensin el', '2026-02-06', '2026-02-06 01:45:59', 3),
('95262b12-145e-4dee-af2a-fd87ed287d1d', 'income', 40000.00, 'uang jajan', 'bekel', '2026-02-06', '2026-02-06 01:45:44', 3),
('9e171fba-4c71-481d-a918-49aae80d5b42', 'income', 20000.00, 'Investasi', 'dikasih una', '2026-02-11', '2026-02-11 01:38:37', 3),
('a0c27d8b-42f8-4ac2-a52d-2148acc29ed2', 'expense', 25000.00, 'Belanja', 'jajan helga', '2026-02-11', '2026-02-12 02:53:16', 3),
('b4b16dfd-a479-4d51-8203-26468c9974fe', 'income', 25000.00, 'Gaji', 'joki web', '2026-02-09', '2026-02-09 01:23:35', 3),
('b784e5f0-cacc-4ac9-ad47-69ac9f3545bf', 'expense', 4000.00, 'Belanja', 'air', '2026-02-18', '2026-02-18 04:04:44', 3),
('c753f3fd-4174-4d42-9290-5bb77c63c4a4', 'expense', 43500.00, 'Belanja', 'jajan helga', '2026-02-10', '2026-02-11 01:35:55', 3),
('cc958aaa-2dab-41e2-8af2-810854fc7653', 'income', 40000.00, 'Investasi', 'uang jajan', '2026-02-13', '2026-02-13 04:13:35', 3),
('dda641ce-9651-4013-9f32-28da3787a048', 'expense', 1000.00, 'Tagihan', 'nabung bareng', '2026-02-23', '2026-02-23 06:45:25', 3),
('fcdef77f-580b-4ff5-9f3f-fbdb99e0e806', 'expense', 10000.00, 'Transport', 'bensin', '2026-02-23', '2026-02-23 06:45:34', 3);

-- --------------------------------------------------------

--
-- Struktur dari tabel `users`
--

CREATE TABLE `users` (
  `id` int NOT NULL,
  `username` varchar(100) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `api_token` varchar(128) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `email` varchar(255) DEFAULT NULL,
  `profile_photo` varchar(1024) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data untuk tabel `users`
--

INSERT INTO `users` (`id`, `username`, `password_hash`, `api_token`, `created_at`, `email`, `profile_photo`) VALUES
(3, 'hanhan', '$2y$10$EtHCohuigCDNRwwC1G8g7O8oymbFyLB8411lvy6UsS1OUSeOcdjTi', 'e29beb755d392e245b588ee5891c43db173e7b6ec19ada61014e9420d1b13443', '2026-02-06 06:23:19', 'raihanfauzan180208@gmail.com', 'http://localhost:8000/get_image.php?file=profile_3_1770610513.jpg'),
(4, 'ujan', '$2y$10$XB4qU8mdqaJ2mDdXuMTjx.g1k4N4NhtEKmV0MB.9eHXYj6ClW7ojm', 'fb684579a5a4ef8eb4b0f31c3da3366b11b64cce493fe511478eab5ff7368123', '2026-02-06 06:23:47', 'ujan@gmail.com', NULL),
(5, 'ehan', '$2y$10$KcQSZ0bLq6R6mMSTOIh1q.vdEo2iLcTXJDxQpHV.Q2SYYVOrH5XN6', '7e6c1cb396c5c31207231262d8438d252d5b85d80f4d9ccd436857efbc89cd93', '2026-02-06 06:41:30', 'ehan@gmail.com', NULL);

--
-- Indeks untuk tabel yang dibuang
--

--
-- Indeks untuk tabel `password_resets`
--
ALTER TABLE `password_resets`
  ADD PRIMARY KEY (`id`);

--
-- Indeks untuk tabel `savings_contributions`
--
ALTER TABLE `savings_contributions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `transaction_id` (`transaction_id`),
  ADD KEY `idx_savings_contributions_goal` (`goal_id`),
  ADD KEY `idx_savings_contributions_user` (`user_id`);

--
-- Indeks untuk tabel `savings_goals`
--
ALTER TABLE `savings_goals`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_savings_goals_user` (`user_id`);

--
-- Indeks untuk tabel `targets`
--
ALTER TABLE `targets`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_deadline` (`deadline`);

--
-- Indeks untuk tabel `transactions`
--
ALTER TABLE `transactions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indeks untuk tabel `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `api_token` (`api_token`);

--
-- AUTO_INCREMENT untuk tabel yang dibuang
--

--
-- AUTO_INCREMENT untuk tabel `password_resets`
--
ALTER TABLE `password_resets`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT untuk tabel `targets`
--
ALTER TABLE `targets`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT untuk tabel `users`
--
ALTER TABLE `users`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- Ketidakleluasaan untuk tabel pelimpahan (Dumped Tables)
--

--
-- Ketidakleluasaan untuk tabel `savings_contributions`
--
ALTER TABLE `savings_contributions`
  ADD CONSTRAINT `savings_contributions_ibfk_1` FOREIGN KEY (`goal_id`) REFERENCES `savings_goals` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `savings_contributions_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `savings_contributions_ibfk_3` FOREIGN KEY (`transaction_id`) REFERENCES `transactions` (`id`) ON DELETE SET NULL;

--
-- Ketidakleluasaan untuk tabel `savings_goals`
--
ALTER TABLE `savings_goals`
  ADD CONSTRAINT `savings_goals_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
