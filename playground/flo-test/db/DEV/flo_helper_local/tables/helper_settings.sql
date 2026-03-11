CREATE TABLE `helper_settings` (
  `id` int NOT NULL AUTO_INCREMENT,
  `setting_key` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL COMMENT 'Setting key (e.g., selectedModelId, systemInstruction)',
  `setting_value` longtext CHARACTER SET latin1 COLLATE latin1_swedish_ci COMMENT 'Setting value (JSON string for complex objects)',
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Last update timestamp',
  PRIMARY KEY (`id`),
  UNIQUE KEY `setting_key` (`setting_key`),
  KEY `idx_setting_key` (`setting_key`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1