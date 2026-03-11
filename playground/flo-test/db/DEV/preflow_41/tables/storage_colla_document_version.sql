CREATE TABLE `storage_colla_document_version` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `uid` varchar(200) NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  `document_uid` varchar(255) DEFAULT NULL,
  `has_snapshot` tinyint(1) DEFAULT NULL,
  `snapshot_path` varchar(255) DEFAULT NULL,
  `created_date` double DEFAULT NULL,
  `updated_date` double DEFAULT NULL,
  `start_time` double DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1