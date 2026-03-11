CREATE TABLE `last_reaction` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `email` varchar(255) NOT NULL,
  `reaction_id` bigint NOT NULL,
  `channel_id` bigint DEFAULT NULL,
  `message_uid` varchar(45) DEFAULT NULL,
  `created_date` double(13,3) NOT NULL,
  `updated_date` double(13,3) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `reaction_id_UNIQUE` (`reaction_id`),
  UNIQUE KEY `channel_id_UNIQUE` (`channel_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1