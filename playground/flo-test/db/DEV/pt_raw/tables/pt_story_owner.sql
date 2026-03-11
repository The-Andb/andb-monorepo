CREATE TABLE `pt_story_owner` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `owner_id` bigint NOT NULL,
  `story_id` bigint NOT NULL,
  `created_date` double DEFAULT NULL,
  `updated_date` double DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1