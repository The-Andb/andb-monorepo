CREATE TABLE `pt_project_epic` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `created_date` double DEFAULT NULL,
  `updated_date` double DEFAULT NULL,
  `pt_epic_id` bigint DEFAULT NULL,
  `project_uid` varchar(200) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `project_tag_id` bigint DEFAULT NULL,
  `collection_id` bigint DEFAULT NULL,
  `project_id` int DEFAULT NULL,
  `url` text,
  `label` json DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_project` (`project_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1