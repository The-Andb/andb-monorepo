CREATE TABLE `storage_download_token` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `path` varchar(600) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `owner` varchar(200) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `token` varchar(500) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `download_time` bigint NOT NULL DEFAULT '0',
  `expired_at` double(13,3) DEFAULT NULL,
  `created_date` double(13,3) DEFAULT NULL,
  `updated_date` double(13,3) DEFAULT NULL,
  `file_uid` varchar(200) COLLATE utf8mb4_general_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci