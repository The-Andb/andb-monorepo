CREATE TABLE `storage_user_usage` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user` varchar(200) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `total_size` bigint DEFAULT NULL,
  `total_file` bigint DEFAULT NULL,
  `created_date` double(13,3) DEFAULT NULL,
  `updated_date` double(13,3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `storage_user_usage_UN` (`user`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1