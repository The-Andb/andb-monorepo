CREATE TABLE `user_notification` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL COMMENT 'User id of member or owner collection',
  `collection_notification_id` bigint NOT NULL DEFAULT '0',
  `status` tinyint NOT NULL DEFAULT '0' COMMENT 'show/hide/archive/trash...',
  `has_mention` tinyint(1) NOT NULL DEFAULT '0',
  `created_date` double(13,3) NOT NULL DEFAULT '0.000',
  `updated_date` double(13,3) NOT NULL DEFAULT '0.000',
  `action_time` double(13,3) NOT NULL DEFAULT '0.000',
  `deleted_date` double(13,3) DEFAULT NULL,
  `counted` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `idx_notification_id` (`collection_notification_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_deleted_date` (`deleted_date`),
  KEY `idx_updated_date` (`updated_date`),
  KEY `idx_status` (`status`),
  KEY `idx_mention` (`has_mention`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1