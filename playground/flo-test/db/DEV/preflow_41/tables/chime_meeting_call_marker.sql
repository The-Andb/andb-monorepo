CREATE TABLE `chime_meeting_call_marker` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `from_phone_number` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `to_phone_number` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `number_call` int DEFAULT '1',
  `avg_time_duration_call` int DEFAULT NULL,
  `frequency_of_calls` int DEFAULT NULL,
  `last_call_time` double DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1