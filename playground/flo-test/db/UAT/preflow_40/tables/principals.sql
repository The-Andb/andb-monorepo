CREATE TABLE `principals` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `uri` varchar(200) COLLATE utf8mb3_unicode_ci NOT NULL,
  `email` varchar(80) COLLATE utf8mb3_unicode_ci DEFAULT NULL,
  `displayname` varchar(80) COLLATE utf8mb3_unicode_ci DEFAULT NULL,
  `vcardurl` varchar(255) COLLATE utf8mb3_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uri` (`uri`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci ROW_FORMAT=DYNAMIC