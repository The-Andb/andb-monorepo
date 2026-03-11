CREATE TABLE `rule` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `match_type` tinyint unsigned NOT NULL COMMENT '- 0: Match all  - 1: Match any',
  `order_number` decimal(20,10) NOT NULL DEFAULT '0.0000000000' COMMENT 'Order of rule	',
  `is_enable` tinyint unsigned DEFAULT '1' COMMENT '- 0: Disable\n- 1: Enable',
  `is_trashed` tinyint NOT NULL DEFAULT '0',
  `created_date` double(13,3) NOT NULL,
  `updated_date` double(13,3) DEFAULT NULL,
  `conditions` json NOT NULL,
  `destinations` json NOT NULL,
  `account_id` bigint unsigned DEFAULT '0',
  `apply_all` tinyint unsigned DEFAULT '1',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uniq_user_id_and_order_number` (`user_id`,`order_number`) USING BTREE,
  KEY `idx_user_id` (`user_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC