CREATE TABLE `rule_filter_action` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `rule_id` bigint unsigned NOT NULL,
  `filter_action_id` bigint unsigned DEFAULT NULL COMMENT 'ID of actions table',
  `filter_action_subvalue` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'ID of collection table	',
  `filter_action_value` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'IMAP path	',
  `created_date` double(13,3) NOT NULL,
  `updated_date` double(13,3) DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_rule_id` (`rule_id`) USING BTREE,
  CONSTRAINT `cst_rule_filter_action_rule_id` FOREIGN KEY (`rule_id`) REFERENCES `rule` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC