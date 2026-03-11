CREATE TABLE `storage_colla_document_version` (
  `uid` varchar(200) COLLATE utf8mb3_unicode_ci NOT NULL,
  `document_uid` varchar(255) COLLATE utf8mb3_unicode_ci DEFAULT NULL,
  `has_snapshot` tinyint(1) DEFAULT NULL,
  `metadata` text COLLATE utf8mb3_unicode_ci,
  `version` int DEFAULT NULL,
  `base_length` double DEFAULT NULL,
  `created_date` double DEFAULT NULL,
  `updated_date` double DEFAULT NULL,
  `edit_date` double DEFAULT NULL,
  `name` varchar(100) COLLATE utf8mb3_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`uid`),
  UNIQUE KEY `storage_colla_document_versions_UN` (`document_uid`,`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci