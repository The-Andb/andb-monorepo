CREATE TABLE `chime_chat_member` (
  `id` int NOT NULL AUTO_INCREMENT,
  `app_instance_user_arn` text CHARACTER SET latin1 COLLATE latin1_swedish_ci,
  `internal_user_id` bigint DEFAULT NULL,
  `internal_user_email` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `created_date` double(13,3) DEFAULT NULL,
  `updated_date` double(13,3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `chime_chat_member_UN` (`internal_user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3