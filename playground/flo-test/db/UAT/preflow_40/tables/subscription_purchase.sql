CREATE TABLE `subscription_purchase` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `sub_id` varchar(255) COLLATE utf8mb3_unicode_ci NOT NULL DEFAULT '',
  `description` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '',
  `transaction_id` varchar(500) COLLATE utf8mb3_unicode_ci NOT NULL DEFAULT '',
  `receipt_data` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `is_current` tinyint unsigned NOT NULL DEFAULT '0',
  `purchase_type` tinyint unsigned NOT NULL DEFAULT '0',
  `purchase_status` tinyint unsigned NOT NULL DEFAULT '1',
  `created_date` double(13,3) NOT NULL,
  `updated_date` double(13,3) DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_on_user_id_and_is_current_and_sub_id` (`user_id`,`is_current`,`sub_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='utf8_unicode_ci'