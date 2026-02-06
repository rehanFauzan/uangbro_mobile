-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Host: localhost:8889
-- Waktu pembuatan: 06 Feb 2026 pada 08.12
-- Versi server: 8.0.44
-- Versi PHP: 7.4.33

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
('1d43cd8c-ae2e-481f-9d87-d977d49976f5', 'expense', 20000.00, 'Bensin', 'bensin', '2026-02-05', '2026-02-05 13:17:53', 3),
('2ab2cba1-e19a-49fd-ae9c-500cf3b53a7d', 'income', 40000.00, 'uang jajan', 'uang jajan', '2026-02-05', '2026-02-05 13:17:16', 3),
('8afcc7a8-0139-439a-9651-6fa11d9fdce8', 'expense', 25000.00, 'Makan', 'mmm', '2026-02-06', '2026-02-06 06:24:09', 4),
('94853bd4-3f71-45a5-8e0a-1da09ec4f83d', 'expense', 20000.00, 'Bensin', 'bensin el', '2026-02-06', '2026-02-06 01:45:59', 3),
('95262b12-145e-4dee-af2a-fd87ed287d1d', 'income', 40000.00, 'uang jajan', 'bekel', '2026-02-06', '2026-02-06 01:45:44', 3);

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
(3, 'hanhan', '$2y$10$fwXxQF2zGAxkUiGLa2UYCeiYvVA3E6UzgmtfRwhsrK5mW7.KOrSvm', 'e29beb755d392e245b588ee5891c43db173e7b6ec19ada61014e9420d1b13443', '2026-02-06 06:23:19', 'raihan@gmail.com', 'http://localhost:8080/get_image.php?file=profile_3_1770364469.jpg'),
(4, 'ujan', '$2y$10$XB4qU8mdqaJ2mDdXuMTjx.g1k4N4NhtEKmV0MB.9eHXYj6ClW7ojm', 'fb684579a5a4ef8eb4b0f31c3da3366b11b64cce493fe511478eab5ff7368123', '2026-02-06 06:23:47', 'ujan@gmail.com', NULL),
(5, 'ehan', '$2y$10$KcQSZ0bLq6R6mMSTOIh1q.vdEo2iLcTXJDxQpHV.Q2SYYVOrH5XN6', '7e6c1cb396c5c31207231262d8438d252d5b85d80f4d9ccd436857efbc89cd93', '2026-02-06 06:41:30', 'ehan@gmail.com', NULL);

--
-- Indeks untuk tabel yang dibuang
--

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
-- AUTO_INCREMENT untuk tabel `users`
--
ALTER TABLE `users`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
