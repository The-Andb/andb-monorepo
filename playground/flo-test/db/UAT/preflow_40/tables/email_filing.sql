CREATE TABLE `email_filing` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `collection_id` bigint unsigned NOT NULL,
  `account_id` bigint unsigned DEFAULT '0',
  `priority` tinyint DEFAULT '0',
  `email_subject` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `frequency_used` int DEFAULT '0',
  `created_date` double(13,3) NOT NULL,
  `updated_date` double(13,3) DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_user_id` (`user_id`) USING BTREE,
  KEY `idx_collection_id` (`collection_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci ROW_FORMAT=DYNAMIC