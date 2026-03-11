CREATE TABLE `user_release` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `release_id` bigint unsigned NOT NULL COMMENT 'ID of Flo app release',
  `user_id` bigint unsigned NOT NULL COMMENT 'ID of group, refer to table Groups',
  `username` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `created_date` double(13,3) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_release_id` (`release_id`) USING BTREE,
  CONSTRAINT `cst_release_id` FOREIGN KEY (`release_id`) REFERENCES `release` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC