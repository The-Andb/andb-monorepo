CREATE TABLE `storage_upload_part` (
  `id` int NOT NULL AUTO_INCREMENT,
  `upload_id` varchar(500) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `part_no` int DEFAULT NULL,
  `etag` varchar(200) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `checksum_sha256` varchar(300) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `size` double DEFAULT NULL,
  `owner` varchar(200) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `created_date` double(13,3) DEFAULT NULL,
  `updated_date` double(13,3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `storage_upload_part_upload_id_IDX` (`upload_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci