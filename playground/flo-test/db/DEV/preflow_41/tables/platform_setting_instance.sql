CREATE TABLE `platform_setting_instance` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `app_reg_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `incoming_call` tinyint(1) NOT NULL DEFAULT '0' COMMENT '0 - Every one (default)\n1 - My Contacts Only\n2 - VIP only',
  `incoming_mail` tinyint(1) NOT NULL DEFAULT '0' COMMENT '0 - Every one (default)\n1 - My Contacts Only \n 2 -VIP only ',
  `filter_chat` tinyint(1) NOT NULL DEFAULT '0' COMMENT '0 - All Messages (default)\n1 - Mention for Me Only',
  `created_date` double(13,3) NOT NULL,
  `updated_date` double(13,3) DEFAULT NULL,
  PRIMARY KEY (`id`,`incoming_mail`),
  UNIQUE KEY `unq_platform_setting` (`user_id`,`app_reg_id`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='utf8mb4_unicode_ci'