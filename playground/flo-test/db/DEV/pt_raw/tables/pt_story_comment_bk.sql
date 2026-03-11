CREATE TABLE `pt_story_comment_bk` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `story_id` bigint NOT NULL,
  `pt_comment_id` bigint NOT NULL,
  `text` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `person_id` bigint NOT NULL,
  `reactions` json DEFAULT NULL,
  `created_date` double(13,3) NOT NULL,
  `updated_date` double(13,3) NOT NULL,
  `deleted_date` double(13,3) DEFAULT NULL,
  `created_at` varchar(45) DEFAULT NULL,
  `updated_at` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique` (`story_id`,`pt_comment_id`),
  KEY `index_project` (`story_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1