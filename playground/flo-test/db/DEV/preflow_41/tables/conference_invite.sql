CREATE TABLE `conference_invite` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `channel_id` bigint NOT NULL,
  `conference_meeting_id` bigint NOT NULL,
  `user_id` bigint NOT NULL DEFAULT '0' COMMENT 'Id of caller',
  `email` varchar(100) NOT NULL COMMENT 'email of invitee',
  `status` int NOT NULL DEFAULT '0' COMMENT 'Reply status or invite status',
  `meeting_id` varchar(100) NOT NULL,
  `external_meeting_id` text,
  `meeting_url` text,
  `provider` varchar(45) NOT NULL DEFAULT 'CHIME',
  `created_date` double(13,3) NOT NULL,
  `updated_date` double(13,3) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unq_channel_id_meeting_id` (`channel_id`,`meeting_id`,`user_id`),
  KEY `idx_channel_id_and_meeting_id` (`channel_id`,`meeting_id`),
  KEY `idx_updated_date` (`updated_date`),
  KEY `idx_created_date` (`created_date`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1