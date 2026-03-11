CREATE TABLE `cards` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `addressbookid` int unsigned NOT NULL,
  `carddata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  `uri` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `lastmodified` int unsigned DEFAULT NULL,
  `etag` varbinary(32) DEFAULT NULL,
  `size` int unsigned NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `addressbookid` (`addressbookid`) USING BTREE,
  KEY `uri` (`uri`) USING BTREE,
  FULLTEXT KEY `carddata` (`carddata`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=DYNAMIC COMMENT='utf8_unicode_ci'