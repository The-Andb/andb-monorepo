CREATE TABLE `storage_colla_document_changes` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `email` varchar(255) DEFAULT NULL,
  `start_time` bigint DEFAULT NULL,
  `update_count` int DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `file_path` varchar(300) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `has_snapshot` tinyint DEFAULT NULL,
  `snapshot_path` varchar(255) DEFAULT NULL,
  `name` varchar(100) DEFAULT NULL,
  `doc_uid` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `storage_colla_document_changes_start_time_IDX` (`start_time`) USING BTREE,
  KEY `storage_colla_document_changes_doc_uid_IDX` (`doc_uid`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1