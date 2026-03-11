CREATE TABLE `pt_project_tag` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `project_uid` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL,
  `name` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL,
  `created_date` double DEFAULT NULL,
  `updated_date` double DEFAULT NULL,
  `pt_label_id` bigint DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci