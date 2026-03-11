ALTER TABLE `helper_settings`
MODIFY COLUMN `setting_key` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL COMMENT 'Setting key (e.g., selectedModelId, systemInstruction)',
MODIFY COLUMN `setting_value` longtext CHARACTER SET latin1 COLLATE latin1_swedish_ci COMMENT 'Setting value (JSON string for complex objects)';