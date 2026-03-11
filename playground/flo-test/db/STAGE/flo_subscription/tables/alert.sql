CREATE TABLE `alert` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL,
  `component_id` bigint NOT NULL DEFAULT '0',
  `reach_limit_at` timestamp(3) NULL DEFAULT NULL,
  `exceed_limit_at` timestamp(3) NULL DEFAULT NULL,
  `limit_type` enum('REACH','EXCEED') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `limit_at` timestamp(3) NULL DEFAULT CURRENT_TIMESTAMP(3),
  `limit_by` enum('API','WORKER') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `last_sent_mail` timestamp NULL DEFAULT NULL COMMENT 'The last mail for grace period sent time',
  `grace_period_mail_count` int NOT NULL DEFAULT '0' COMMENT 'Number of the sent mails',
  `deleted_at` timestamp NULL DEFAULT NULL COMMENT 'The time deleted',
  `created_date` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `created_year` int GENERATED ALWAYS AS (year(`created_date`)) STORED NOT NULL,
  `updated_date` timestamp(3) NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`,`created_year`),
  KEY `idx_user_component` (`user_id`,`component_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
/*!50100 PARTITION BY RANGE (`created_year`)
(PARTITION p2024 VALUES LESS THAN (2025) ENGINE = InnoDB,
 PARTITION p2025 VALUES LESS THAN (2026) ENGINE = InnoDB,
 PARTITION p2026 VALUES LESS THAN (2027) ENGINE = InnoDB,
 PARTITION p2027 VALUES LESS THAN (2028) ENGINE = InnoDB,
 PARTITION p2028 VALUES LESS THAN (2029) ENGINE = InnoDB,
 PARTITION p2029 VALUES LESS THAN (2030) ENGINE = InnoDB,
 PARTITION p2030 VALUES LESS THAN (2031) ENGINE = InnoDB,
 PARTITION pmax VALUES LESS THAN MAXVALUE ENGINE = InnoDB) */