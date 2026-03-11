CREATE TABLE `pt_story_comment` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `story_id` bigint NOT NULL,
  `pt_comment_id` bigint NOT NULL,
  `text` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `person_id` bigint NOT NULL,
  `reactions` json DEFAULT NULL,
  `created_date` double(13,3) NOT NULL,
  `updated_date` double(13,3) NOT NULL,
  `deleted_date` double(13,3) DEFAULT NULL,
  `created_at` varchar(45) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `updated_at` varchar(45) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_story_comment` (`story_id`,`pt_comment_id`),
  KEY `index_project` (`story_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1