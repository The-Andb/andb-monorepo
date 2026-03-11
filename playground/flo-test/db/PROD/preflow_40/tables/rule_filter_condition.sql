CREATE TABLE `rule_filter_condition` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `rule_id` bigint unsigned NOT NULL,
  `filter_condition_id` bigint unsigned NOT NULL COMMENT 'ID of email_fields table',
  `filter_operator_id` bigint unsigned NOT NULL,
  `filter_value` varchar(255) COLLATE utf8mb4_general_ci NOT NULL COMMENT 'keywords to filter	',
  `created_date` double(13,3) NOT NULL,
  `updated_date` double(13,3) DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_rule_filter_condition_rule_id` (`rule_id`) USING BTREE,
  CONSTRAINT `cst_rule_filter_condition_rule_id` FOREIGN KEY (`rule_id`) REFERENCES `rule` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC