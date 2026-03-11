CREATE TABLE `calendarchanges` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `uri` varchar(200) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `synctoken` int unsigned NOT NULL,
  `calendarid` int unsigned NOT NULL,
  `operation` tinyint(1) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `calendarid_synctoken` (`calendarid`,`synctoken`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1