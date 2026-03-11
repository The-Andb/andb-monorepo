CREATE TABLE `pt_story_review` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `story_id` bigint DEFAULT NULL,
  `story_uid` varchar(200) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `review_type_id` bigint DEFAULT NULL,
  `reviewer_id` bigint DEFAULT NULL,
  `status` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `created_date` double DEFAULT NULL,
  `updated_date` double DEFAULT NULL,
  `pt_review_id` bigint DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1