CREATE TABLE `release_group` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `release_id` bigint unsigned NOT NULL COMMENT 'ID of Flo app release',
  `group_id` bigint unsigned DEFAULT NULL COMMENT 'The ID of the group, refer to the table "groups"	',
  `created_date` double(13,3) NOT NULL,
  `updated_date` double(13,3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_on_release_id_and_group_id` (`release_id`,`group_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci