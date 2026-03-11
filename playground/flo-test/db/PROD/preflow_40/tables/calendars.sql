CREATE TABLE `calendars` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `synctoken` int unsigned NOT NULL DEFAULT '1',
  `components` varbinary(255) DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci ROW_FORMAT=DYNAMIC