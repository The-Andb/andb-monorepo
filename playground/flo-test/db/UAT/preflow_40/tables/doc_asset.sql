CREATE TABLE `doc_asset` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `device_id` int NOT NULL DEFAULT '0',
  `bookmark` tinyblob NOT NULL,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '',
  `source_type` int NOT NULL DEFAULT '0',
  `url` varchar(500) COLLATE utf8mb3_unicode_ci NOT NULL DEFAULT '',
  `created_date` double(13,3) NOT NULL,
  `updated_date` double(13,3) DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='utf8_unicode_ci'