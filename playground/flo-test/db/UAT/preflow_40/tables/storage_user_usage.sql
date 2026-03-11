CREATE TABLE `storage_user_usage` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user` varchar(200) COLLATE utf8mb3_unicode_ci DEFAULT NULL,
  `total_size` bigint DEFAULT NULL,
  `total_file` bigint DEFAULT NULL,
  `created_date` double(13,3) DEFAULT NULL,
  `updated_date` double(13,3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `storage_user_usage_UN` (`user`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci