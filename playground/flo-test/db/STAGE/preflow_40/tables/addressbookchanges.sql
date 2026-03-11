CREATE TABLE `addressbookchanges` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `uri` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `synctoken` int unsigned NOT NULL,
  `addressbookid` int unsigned NOT NULL,
  `operation` tinyint NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `addressbookid_synctoken` (`addressbookid`,`synctoken`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=DYNAMIC