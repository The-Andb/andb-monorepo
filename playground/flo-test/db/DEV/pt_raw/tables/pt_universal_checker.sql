CREATE TABLE `pt_universal_checker` (
  `id` int NOT NULL AUTO_INCREMENT,
  `dest_project_id` int NOT NULL,
  `dest_story_id` int NOT NULL,
  `dest_object_uid` varchar(100) NOT NULL,
  `src` enum('description','comment','blocker','review','task') NOT NULL,
  `src_project_id` int DEFAULT NULL,
  `src_story_id` int DEFAULT NULL,
  `pt_src_id` int NOT NULL DEFAULT '0',
  `collection_id` varchar(45) NOT NULL,
  `status` enum('pending','failed','success') NOT NULL DEFAULT 'pending',
  `created_date` double DEFAULT NULL,
  `updated_date` double DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci