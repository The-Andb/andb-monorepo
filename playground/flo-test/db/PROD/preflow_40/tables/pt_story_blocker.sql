CREATE TABLE `pt_story_blocker` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `story_uid` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL,
  `user_id` bigint DEFAULT NULL,
  `description` text CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci,
  `resolved` tinyint(1) DEFAULT NULL,
  `created_date` double DEFAULT NULL,
  `updated_date` double DEFAULT NULL,
  `pt_block_id` bigint DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci