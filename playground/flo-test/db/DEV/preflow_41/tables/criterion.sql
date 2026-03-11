CREATE TABLE `criterion` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `criterion_type` tinyint NOT NULL DEFAULT '0',
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `point` int NOT NULL DEFAULT '0',
  `priority` int NOT NULL DEFAULT '1',
  `created_date` double(13,3) NOT NULL,
  `updated_date` double(13,3) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='utf8mb4_unicode_ci'