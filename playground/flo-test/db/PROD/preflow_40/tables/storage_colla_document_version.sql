CREATE TABLE `storage_colla_document_version` (
  `uid` varchar(200) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `document_uid` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `has_snapshot` tinyint(1) DEFAULT NULL,
  `metadata` text CHARACTER SET latin1 COLLATE latin1_swedish_ci,
  `version` int DEFAULT NULL,
  `base_length` double DEFAULT NULL,
  `created_date` double DEFAULT NULL,
  `updated_date` double DEFAULT NULL,
  `edit_date` double DEFAULT NULL,
  `name` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  PRIMARY KEY (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci