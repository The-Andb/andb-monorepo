CREATE TABLE `audit_log` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `table_name` varchar(100) DEFAULT NULL,
  `operation` enum('INSERT','UPDATE','DELETE') DEFAULT NULL,
  `record_id` bigint DEFAULT NULL,
  `old_data` json DEFAULT NULL,
  `new_data` json DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1