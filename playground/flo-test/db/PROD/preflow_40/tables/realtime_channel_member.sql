CREATE TABLE `realtime_channel_member` (
  `id` int NOT NULL AUTO_INCREMENT,
  `email` varchar(100) NOT NULL,
  `channel_id` int NOT NULL,
  `channel_name` varchar(100) DEFAULT NULL,
  `user_id` bigint DEFAULT NULL,
  `role` int NOT NULL DEFAULT '2' COMMENT '  OWNER = 0,\\\\n  VIEWER = 1,\\\\n  EDITOR = 2,',
  `revoke_date` double(13,3) DEFAULT NULL,
  `created_date` double(13,3) NOT NULL,
  `updated_date` double(13,3) NOT NULL,
  `channel_key` text,
  `notification_chat` tinyint(1) NOT NULL DEFAULT '2',
  `notification_call` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `notification_channel_member_UN` (`email`,`channel_id`),
  KEY `notification_channel_member_channel_id_IDX` (`channel_id`) USING BTREE,
  KEY `idx_email` (`email`) USING BTREE,
  KEY `idx_channel_name` (`channel_name`,`email`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1