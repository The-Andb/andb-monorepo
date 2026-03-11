CREATE TABLE `schedulingobjects` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `principaluri` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `calendardata` mediumblob,
  `uri` varchar(200) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `lastmodified` int unsigned DEFAULT NULL,
  `etag` varchar(32) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `size` int unsigned NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `principaluri` (`principaluri`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci ROW_FORMAT=DYNAMIC