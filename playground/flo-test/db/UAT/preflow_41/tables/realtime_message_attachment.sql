CREATE TABLE `realtime_message_attachment` (
  `id` int NOT NULL AUTO_INCREMENT,
  `message_uid` varchar(100) NOT NULL,
  `file_id` int DEFAULT NULL,
  `created_date` double(13,3) DEFAULT NULL,
  `updated_date` double(13,3) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1