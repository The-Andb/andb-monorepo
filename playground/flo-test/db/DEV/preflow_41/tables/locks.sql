CREATE TABLE `locks` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `owner` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci DEFAULT NULL,
  `timeout` int unsigned DEFAULT NULL,
  `created` int DEFAULT NULL,
  `token` varbinary(100) DEFAULT NULL,
  `scope` tinyint DEFAULT NULL,
  `depth` tinyint DEFAULT NULL,
  `uri` varbinary(1000) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `token` (`token`),
  KEY `uri` (`uri`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1