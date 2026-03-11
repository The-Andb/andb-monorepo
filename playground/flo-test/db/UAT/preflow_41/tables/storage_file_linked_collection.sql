CREATE TABLE `storage_file_linked_collection` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `collection_id` bigint NOT NULL,
  `collection_type` varchar(100) NOT NULL,
  `file_uid` varchar(200) NOT NULL,
  `linked_by` varchar(200) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `created_date` double(13,3) DEFAULT NULL,
  `updated_date` double(13,3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_sflc_file_uid` (`file_uid`),
  KEY `idx_sflc_collection_id` (`collection_id`),
  KEY `idx_sflc_linked_by` (`linked_by`),
  KEY `idx_sflc_collection_type` (`collection_type`),
  KEY `idx_sflc_file_uid_id` (`file_uid`,`id`),
  KEY `idx_sflc_collection_id_file_uid` (`collection_id`,`file_uid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1