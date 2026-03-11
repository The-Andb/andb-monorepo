CREATE TABLE `pt_project_activity` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `guid` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL,
  `kind` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL,
  `project_version` int DEFAULT NULL,
  `message` varchar(300) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL,
  `changes` text CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci,
  `primary_resources` text CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci,
  `project_uid` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL,
  `performed_by` bigint DEFAULT NULL,
  `occurred_date` double DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci