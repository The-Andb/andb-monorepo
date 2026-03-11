CREATE TABLE `send_mail` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `to_email` varchar(255) COLLATE utf8mb3_unicode_ci NOT NULL DEFAULT '',
  `subject` varchar(255) COLLATE utf8mb3_unicode_ci NOT NULL DEFAULT '',
  `template` varchar(255) COLLATE utf8mb3_unicode_ci NOT NULL DEFAULT '',
  `percent` int NOT NULL DEFAULT '0',
  `upgrade_to` varchar(255) COLLATE utf8mb3_unicode_ci NOT NULL DEFAULT '',
  `expired` varchar(255) COLLATE utf8mb3_unicode_ci NOT NULL DEFAULT '',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='utf8_unicode_ci'