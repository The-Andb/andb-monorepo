CREATE TABLE `storage_file_edit_history` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `file_uid` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `user` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `edit_details` text CHARACTER SET latin1 COLLATE latin1_swedish_ci,
  `base_on_version` int NOT NULL,
  `created_date` double(13,3) NOT NULL,
  `updated_date` double(13,3) NOT NULL,
  `apply_to_version` int DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci