CREATE TABLE `virtual_alias` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `domain_id` bigint unsigned NOT NULL,
  `source` varchar(100) NOT NULL,
  `destination` varchar(9000) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_domain_id` (`domain_id`) USING BTREE,
  KEY `idx_source` (`source`) USING BTREE,
  CONSTRAINT `cst_virtual_domain_by_domain_id` FOREIGN KEY (`domain_id`) REFERENCES `virtual_domain` (`id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=latin1 ROW_FORMAT=DYNAMIC COMMENT='utf8_general_ci'