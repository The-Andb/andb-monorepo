CREATE TABLE `groupmembers` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `principal_id` int unsigned NOT NULL,
  `member_id` int unsigned NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `principal_id` (`principal_id`,`member_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1