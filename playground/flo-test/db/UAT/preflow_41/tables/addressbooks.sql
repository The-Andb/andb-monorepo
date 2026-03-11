CREATE TABLE `addressbooks` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `principaluri` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `displayname` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `uri` varchar(200) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `description` text CHARACTER SET latin1 COLLATE latin1_swedish_ci,
  `synctoken` int unsigned NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_principaluri` (`principaluri`,`uri`),
  KEY `uri_idx` (`uri`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1