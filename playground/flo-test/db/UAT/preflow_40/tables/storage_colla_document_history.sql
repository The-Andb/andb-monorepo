CREATE TABLE `storage_colla_document_history` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `doc_uid` varchar(200) COLLATE utf8mb3_unicode_ci DEFAULT NULL,
  `change` text COLLATE utf8mb3_unicode_ci,
  `change_by` varchar(100) COLLATE utf8mb3_unicode_ci DEFAULT NULL,
  `change_time` double DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `storage_colla_document_history_doc_uid_IDX` (`doc_uid`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci