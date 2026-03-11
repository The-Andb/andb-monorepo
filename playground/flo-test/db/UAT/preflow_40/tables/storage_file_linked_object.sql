CREATE TABLE `storage_file_linked_object` (
  `id` int NOT NULL AUTO_INCREMENT,
  `file_uid` varchar(200) COLLATE utf8mb3_unicode_ci NOT NULL,
  `object_uid` varchar(200) COLLATE utf8mb3_unicode_ci DEFAULT NULL,
  `object_type` int NOT NULL,
  `object_id` bigint DEFAULT NULL,
  `linked_by` varchar(200) COLLATE utf8mb3_unicode_ci DEFAULT NULL,
  `created_date` double(13,3) DEFAULT NULL,
  `updated_date` double(13,3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `storage_file_linked_object_file_uid_IDX` (`file_uid`) USING BTREE,
  KEY `storage_file_linked_object_object_type_IDX` (`object_type`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci