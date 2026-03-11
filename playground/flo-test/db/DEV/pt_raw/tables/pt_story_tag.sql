CREATE TABLE `pt_story_tag` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `story_uid` varchar(200) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `story_id` bigint DEFAULT NULL,
  `project_tag_id` bigint DEFAULT NULL,
  `created_date` double DEFAULT NULL,
  `updated_date` double DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1