CREATE TABLE `permission` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `feature_id` int DEFAULT NULL,
  `role_id` int DEFAULT NULL,
  `permission_value` int DEFAULT NULL COMMENT 'sum of total permistion granted',
  `created_date` double(13,3) NOT NULL,
  `updated_date` double(13,3) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1