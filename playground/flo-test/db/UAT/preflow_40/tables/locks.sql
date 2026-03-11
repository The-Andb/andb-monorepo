CREATE TABLE `locks` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `owner` varchar(100) COLLATE utf8mb3_unicode_ci DEFAULT NULL,
  `timeout` int unsigned DEFAULT NULL,
  `created` int DEFAULT NULL,
  `token` varbinary(100) DEFAULT NULL,
  `scope` tinyint DEFAULT NULL,
  `depth` tinyint DEFAULT NULL,
  `uri` varbinary(1000) DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `token` (`token`) USING BTREE,
  KEY `uri` (`uri`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci ROW_FORMAT=DYNAMIC