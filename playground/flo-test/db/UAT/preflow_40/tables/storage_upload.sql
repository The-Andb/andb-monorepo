CREATE TABLE `storage_upload` (
  `id` int NOT NULL AUTO_INCREMENT,
  `upload_id` varchar(500) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `file_uid` varchar(200) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `path` varchar(300) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `total_size` double DEFAULT NULL,
  `owner` varchar(200) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `total_part` int DEFAULT NULL,
  `status` int DEFAULT NULL COMMENT '0: pending, 1: uploading, 2: completed, 3: failed, 4: abort',
  `created_date` double(13,3) DEFAULT NULL,
  `updated_date` double(13,3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `upload_UN` (`upload_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci