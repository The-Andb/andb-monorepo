CREATE TABLE `api_last_modified` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `api_name` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `api_modified_date` double(13,3) NOT NULL,
  `created_date` double(13,3) NOT NULL,
  `updated_date` double(13,3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_on_user_id_and_api_name` (`user_id`,`api_name`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_api_name` (`api_name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COMMENT='utf8_unicode_ci'