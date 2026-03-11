CREATE TABLE `calendar_changes_global` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `synctoken` int unsigned NOT NULL,
  `calendarid` int unsigned NOT NULL,
  `operation` tinyint(1) NOT NULL,
  `deleted_calendar_uri` varchar(200) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `owner_deleted_calendar` varchar(200) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `calendar_changes_global_synctoken_IDX` (`synctoken`) USING BTREE,
  KEY `idx_calendar_changes_global_calendarid_synctoken` (`calendarid`,`synctoken`),
  KEY `idx_calendar_changes_global_owner_synctoken` (`owner_deleted_calendar`,`synctoken`,`calendarid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1