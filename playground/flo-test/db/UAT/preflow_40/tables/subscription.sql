CREATE TABLE `subscription` (
  `id` varchar(255) COLLATE utf8mb3_unicode_ci NOT NULL DEFAULT '',
  `name` varchar(255) COLLATE utf8mb3_unicode_ci NOT NULL DEFAULT '',
  `price` float NOT NULL DEFAULT '0',
  `period` int NOT NULL DEFAULT '0',
  `auto_renew` int NOT NULL DEFAULT '0',
  `description` varchar(255) COLLATE utf8mb3_unicode_ci NOT NULL DEFAULT '',
  `subs_type` int NOT NULL DEFAULT '0',
  `order_number` int NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='utf8_unicode_ci'