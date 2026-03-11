CREATE TABLE `realtime_user_usage` (
  `id` int NOT NULL AUTO_INCREMENT,
  `email` varchar(100) NOT NULL,
  `message_size_usage` int NOT NULL DEFAULT '0',
  `message_count` int NOT NULL DEFAULT '0',
  `channel_count` int NOT NULL DEFAULT '0',
  `attachment_size_usage` int NOT NULL DEFAULT '0',
  `attachment_count` int NOT NULL DEFAULT '0',
  `created_date` double(13,3) NOT NULL,
  `updated_date` double(13,3) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unq_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1