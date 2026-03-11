CREATE TABLE `storage_file_linked_object` (
  `id` int NOT NULL AUTO_INCREMENT,
  `file_uid` varchar(200) NOT NULL,
  `object_uid` varchar(200) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `object_type` int NOT NULL,
  `object_id` bigint DEFAULT NULL,
  `linked_by` varchar(200) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `created_date` double(13,3) DEFAULT NULL,
  `updated_date` double(13,3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `storage_file_linked_object_file_uid_IDX` (`file_uid`) USING BTREE,
  KEY `storage_file_linked_object_object_type_IDX` (`object_type`) USING BTREE,
  KEY `linked_by_object_id_idx` (`linked_by`,`object_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1