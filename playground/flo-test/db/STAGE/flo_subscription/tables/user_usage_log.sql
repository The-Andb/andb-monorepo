CREATE TABLE `user_usage_log` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL,
  `created_date` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_date` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `last_scan_at` timestamp(3) NOT NULL DEFAULT '0000-00-00 00:00:00.000',
  `need_to_scan` tinyint(1) GENERATED ALWAYS AS ((`updated_date` > `last_scan_at`)) VIRTUAL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unq_user_id` (`user_id`),
  KEY `idx_updated_date` (`updated_date`),
  KEY `idx_last_scan_at` (`last_scan_at`),
  KEY `idx_need_to_scan` (`need_to_scan`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci