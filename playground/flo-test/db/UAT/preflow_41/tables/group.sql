CREATE TABLE `group` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `group_type` enum('0','1','2') CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `internal_group` enum('0','1','2','3','4','5','6') CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `created_date` double(13,3) NOT NULL,
  `updated_date` double(13,3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_name_type_internal` (`name`,`group_type`,`internal_group`) USING BTREE,
  KEY `idx_group_type` (`group_type`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1