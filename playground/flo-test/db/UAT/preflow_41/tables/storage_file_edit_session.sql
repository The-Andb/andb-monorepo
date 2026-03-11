CREATE TABLE `storage_file_edit_session` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user` varchar(200) NOT NULL,
  `edit_token` varchar(255) NOT NULL,
  `version` int NOT NULL DEFAULT '1',
  `temp_file_path` varchar(255) NOT NULL,
  `file_uid` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `created_date` double(13,3) NOT NULL,
  `updated_date` double(13,3) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `storage_edit_sesions_UN` (`edit_token`),
  KEY `storage_edit_sesions_file_uid_IDX` (`file_uid`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1