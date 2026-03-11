CREATE TABLE `pt_project_tag` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `project_uid` varchar(200) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `name` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `created_date` double DEFAULT NULL,
  `updated_date` double DEFAULT NULL,
  `pt_label_id` bigint DEFAULT NULL,
  `project_id` int DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1