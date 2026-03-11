CREATE TABLE `chime_meeting_caller` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `phone_number` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `provision_date` double DEFAULT NULL,
  `release_date` double DEFAULT NULL,
  `status` int DEFAULT NULL COMMENT '1: in use, 2: locked, 3: released',
  `phone_number_id` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci