CREATE TABLE `chime_meeting_call_maked` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `from_phone_number` varchar(100) COLLATE utf8mb3_unicode_ci DEFAULT NULL,
  `to_phone_number` varchar(100) COLLATE utf8mb3_unicode_ci DEFAULT NULL,
  `number_call` int DEFAULT '1',
  `avg_time_duration_call` int DEFAULT NULL,
  `frequency_of_calls` int DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci