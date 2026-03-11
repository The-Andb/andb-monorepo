CREATE TABLE `credential` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `created_date` double(13,3) DEFAULT NULL,
  `updated_date` double(13,3) DEFAULT NULL,
  `data_encrypted` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `type` tinyint(1) NOT NULL DEFAULT '0',
  `checksum` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unq_credential` (`user_id`,`type`,`checksum`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COMMENT='utf8_unicode_ci'