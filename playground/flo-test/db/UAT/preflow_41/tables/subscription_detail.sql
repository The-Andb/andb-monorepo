CREATE TABLE `subscription_detail` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `sub_id` varchar(255) NOT NULL DEFAULT '',
  `com_id` int NOT NULL DEFAULT '0',
  `sub_value` int NOT NULL DEFAULT '0',
  `description` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COMMENT='utf8_unicode_ci'