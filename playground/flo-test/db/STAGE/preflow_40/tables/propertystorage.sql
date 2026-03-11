CREATE TABLE `propertystorage` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `path` varbinary(1024) NOT NULL,
  `name` varbinary(100) NOT NULL,
  `valuetype` int unsigned DEFAULT NULL,
  `value` mediumblob,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `path_property` (`path`,`name`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=DYNAMIC