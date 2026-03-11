CREATE TABLE `pt_story_blocker` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `pt_blocker_id` bigint DEFAULT NULL,
  `story_id` bigint DEFAULT NULL,
  `dest_story_id` bigint DEFAULT NULL,
  `person_id` int DEFAULT NULL,
  `user_id` bigint DEFAULT NULL,
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
  `resolved` tinyint(1) DEFAULT NULL,
  `created_date` double DEFAULT NULL,
  `updated_date` double DEFAULT NULL,
  `kind` varchar(20) DEFAULT NULL,
  `created_at` varchar(45) DEFAULT NULL,
  `updated_at` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1