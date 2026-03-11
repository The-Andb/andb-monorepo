CREATE TABLE `calendarchanges` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `uri` varchar(200) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `synctoken` int unsigned NOT NULL,
  `calendarid` int unsigned NOT NULL,
  `operation` tinyint(1) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `calendarid_synctoken` (`calendarid`,`synctoken`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=DYNAMIC