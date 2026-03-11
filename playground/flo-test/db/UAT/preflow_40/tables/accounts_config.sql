CREATE TABLE `accounts_config` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `uid` varchar(150) COLLATE utf8mb3_unicode_ci DEFAULT NULL,
  `password` varchar(150) COLLATE utf8mb3_unicode_ci DEFAULT NULL,
  `email` varchar(255) COLLATE utf8mb3_unicode_ci DEFAULT NULL,
  `refreshToken` varchar(255) COLLATE utf8mb3_unicode_ci DEFAULT NULL,
  `accessToken` varchar(255) COLLATE utf8mb3_unicode_ci DEFAULT NULL,
  `expire_time` int NOT NULL,
  `server_address` varchar(255) COLLATE utf8mb3_unicode_ci DEFAULT NULL,
  `con_type` tinyint unsigned DEFAULT '1' COMMENT '1: Login via Oauth2 Account',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uniq_email` (`email`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci ROW_FORMAT=DYNAMIC