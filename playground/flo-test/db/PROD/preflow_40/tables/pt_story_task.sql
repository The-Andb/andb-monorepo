CREATE TABLE `pt_story_task` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `story_uid` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `description` text CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci,
  `status` int NOT NULL DEFAULT '0' COMMENT '0: pending, 1: processing, 2: complete',
  `due_date` double DEFAULT NULL,
  `position` int DEFAULT '0',
  `created_date` double DEFAULT NULL,
  `updated_date` double DEFAULT NULL,
  `user_id` bigint DEFAULT NULL,
  `pt_story_task_id` bigint DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci