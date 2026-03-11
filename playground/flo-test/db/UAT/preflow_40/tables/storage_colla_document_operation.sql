CREATE TABLE `storage_colla_document_operation` (
  `uid` varchar(255) COLLATE utf8mb3_unicode_ci NOT NULL,
  `document_version_uid` varchar(255) COLLATE utf8mb3_unicode_ci DEFAULT NULL,
  `operation` json DEFAULT NULL,
  `created_date` double DEFAULT NULL,
  `updated_date` double DEFAULT NULL,
  PRIMARY KEY (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci