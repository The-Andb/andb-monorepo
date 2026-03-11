CREATE TABLE `groupmembers` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `principal_id` int unsigned NOT NULL,
  `member_id` int unsigned NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `principal_id` (`principal_id`,`member_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=DYNAMIC