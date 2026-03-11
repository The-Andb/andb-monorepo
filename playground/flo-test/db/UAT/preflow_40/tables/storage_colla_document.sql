CREATE TABLE `storage_colla_document` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `uid` varchar(255) COLLATE utf8mb3_unicode_ci NOT NULL,
  `name` varchar(255) COLLATE utf8mb3_unicode_ci NOT NULL,
  `last_version` bigint DEFAULT '0',
  `object_type` int DEFAULT NULL,
  `object_id` bigint DEFAULT NULL,
  `object_uid` varchar(255) COLLATE utf8mb3_unicode_ci DEFAULT NULL,
  `created_date` double DEFAULT NULL,
  `updated_date` double DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `storage_colla_document_object_type_IDX` (`object_type`) USING BTREE,
  KEY `storage_colla_document_object_type_object_id_IDX` (`object_type`,`object_id`) USING BTREE,
  KEY `storage_colla_document_object_type_object_uid_IDX` (`object_type`,`object_uid`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci