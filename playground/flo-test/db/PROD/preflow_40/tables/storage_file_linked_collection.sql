CREATE TABLE `storage_file_linked_collection` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `collection_id` bigint NOT NULL,
  `collection_type` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `file_uid` varchar(200) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `linked_by` varchar(200) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `created_date` double(13,3) DEFAULT NULL,
  `updated_date` double(13,3) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci