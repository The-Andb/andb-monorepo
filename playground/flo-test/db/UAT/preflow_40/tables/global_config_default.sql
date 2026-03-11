CREATE TABLE `global_config_default` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `working_time` json NOT NULL,
  `week_start` int NOT NULL DEFAULT '0',
  `event_duration` int NOT NULL DEFAULT '3600',
  `alert_before` int NOT NULL DEFAULT '0',
  `default_alert_ade` int DEFAULT '0',
  `snooze_default` int NOT NULL DEFAULT '900',
  `default_alert_todo` int DEFAULT '0',
  `due_task` int NOT NULL DEFAULT '0',
  `task_duration` int NOT NULL DEFAULT '1800',
  `created_date` double(13,3) NOT NULL,
  `updated_date` double(13,3) DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='utf8_unicode_ci'