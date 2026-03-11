CREATE TABLE `platform_setting` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `data_setting` json NOT NULL,
  `app_reg_id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `app_version` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `incoming_call` tinyint(1) NOT NULL DEFAULT '0' COMMENT '0 - Every one (default)\n1 - My Contacts Only\n2 - VIP only',
  `incoming_mail` tinyint(1) NOT NULL DEFAULT '0' COMMENT '0 - Every one (default)\n1 - My Contacts Only \n 2 -VIP only ',
  `filter_chat` tinyint(1) NOT NULL DEFAULT '0' COMMENT '0 - All Messages (default)\n1 - Mention for Me Only',
  `device_uid` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL DEFAULT '',
  `created_date` double(13,3) NOT NULL,
  `updated_date` double(13,3) DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `unq_platform_setting` (`user_id`,`app_reg_id`,`app_version`),
  KEY `idx_user_id` (`user_id`) USING BTREE,
  KEY `idx_on_user_id_and_app_version` (`user_id`,`app_version`) USING BTREE,
  KEY `idx_on_user_id_and_app_reg_id` (`user_id`,`app_reg_id`) USING BTREE,
  KEY `idx_on_user_id_and_app_reg_id_and_app_version` (`user_id`,`app_reg_id`,`app_version`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='utf8mb4_unicode_ci'