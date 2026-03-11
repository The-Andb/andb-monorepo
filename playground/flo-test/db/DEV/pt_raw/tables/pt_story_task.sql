CREATE TABLE `pt_story_task` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `story_uid` varchar(200) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `story_id` int DEFAULT NULL,
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
  `status` int NOT NULL DEFAULT '0' COMMENT '0: pending, 1: processing, 2: complete',
  `due_date` double DEFAULT NULL,
  `position` int DEFAULT '0',
  `created_date` double DEFAULT NULL,
  `updated_date` double DEFAULT NULL,
  `user_id` bigint DEFAULT NULL,
  `pt_story_task_id` bigint DEFAULT NULL,
  `created_at` varchar(45) DEFAULT NULL,
  `updated_at` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1