CREATE TABLE `calendarchanges` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `uri` varchar(200) COLLATE utf8mb3_unicode_ci NOT NULL,
  `synctoken` int unsigned NOT NULL,
  `calendarid` int unsigned NOT NULL,
  `operation` tinyint(1) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `calendarid_synctoken` (`calendarid`,`synctoken`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci ROW_FORMAT=DYNAMIC