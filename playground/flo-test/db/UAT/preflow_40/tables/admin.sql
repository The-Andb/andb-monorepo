CREATE TABLE `admin` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `email` varchar(255) COLLATE utf8mb3_unicode_ci NOT NULL,
  `verify_code` varchar(255) COLLATE utf8mb3_unicode_ci NOT NULL DEFAULT '',
  `time_code_expire` int NOT NULL DEFAULT '0',
  `role` tinyint NOT NULL DEFAULT '0' COMMENT '0 : QA\n1 : ',
  `receive_mail` tinyint(1) NOT NULL DEFAULT '0',
  `created_date` double(13,3) NOT NULL,
  `updated_date` double(13,3) DEFAULT NULL,
  `is_2fa_enabled` tinyint(1) NOT NULL DEFAULT '0',
  `secret_key` text COLLATE utf8mb3_unicode_ci,
  `role_id` bigint NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uniq_email` (`email`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='utf8_unicode_ci'