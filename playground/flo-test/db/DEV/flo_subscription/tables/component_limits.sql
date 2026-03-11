CREATE TABLE `component_limits` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `component_id` bigint NOT NULL DEFAULT '0',
  `threshold` bigint NOT NULL DEFAULT '0' COMMENT 'threshold in percent',
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `created_date` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_date` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `idx_component_id` (`component_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci