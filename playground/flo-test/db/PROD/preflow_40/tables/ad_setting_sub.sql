CREATE TABLE `ad_setting_sub` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `notice_by_email` tinyint NOT NULL DEFAULT '1',
  `notice_by_push` tinyint NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='utf8_unicode_ci'