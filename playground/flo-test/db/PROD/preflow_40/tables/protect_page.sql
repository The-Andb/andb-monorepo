CREATE TABLE `protect_page` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `verify_code` text CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `checksum` varchar(128) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `time_code_expire` int NOT NULL DEFAULT '0',
  `created_date` double(13,3) NOT NULL,
  `updated_date` double(13,3) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci COMMENT='utf8_unicode_ci'