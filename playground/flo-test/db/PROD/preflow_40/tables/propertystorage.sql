CREATE TABLE `propertystorage` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `path` varbinary(1024) NOT NULL,
  `name` varbinary(100) NOT NULL,
  `valuetype` int unsigned DEFAULT NULL,
  `value` mediumblob,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `path_property` (`path`,`name`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci ROW_FORMAT=DYNAMIC