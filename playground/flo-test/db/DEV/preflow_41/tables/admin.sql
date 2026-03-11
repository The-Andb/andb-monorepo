CREATE TABLE `admin` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `email` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `verify_code` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `time_code_expire` int NOT NULL DEFAULT '0',
  `role_id` bigint NOT NULL DEFAULT '0',
  `role` tinyint NOT NULL DEFAULT '0' COMMENT '0 : QA\n1 : ',
  `created_date` double(13,3) NOT NULL,
  `receive_mail` tinyint(1) NOT NULL DEFAULT '0',
  `updated_date` double(13,3) DEFAULT NULL,
  `is_2fa_enabled` tinyint(1) NOT NULL DEFAULT '0',
  `secret_key` text CHARACTER SET latin1 COLLATE latin1_swedish_ci,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COMMENT='utf8_unicode_ci'