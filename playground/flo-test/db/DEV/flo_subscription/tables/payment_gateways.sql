CREATE TABLE `payment_gateways` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `merchant_id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `merchant_type` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `merchant_token` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `merchant_signature` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `merchant_description` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_date` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_date` timestamp(3) NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_is_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci