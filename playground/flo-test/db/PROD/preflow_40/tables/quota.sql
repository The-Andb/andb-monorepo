CREATE TABLE `quota` (
  `username` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `bytes` bigint NOT NULL DEFAULT '0',
  `messages` int NOT NULL DEFAULT '0',
  `cal_bytes` bigint NOT NULL DEFAULT '0',
  `card_bytes` bigint NOT NULL DEFAULT '0',
  `file_bytes` bigint NOT NULL DEFAULT '0',
  `num_sent` int NOT NULL DEFAULT '0',
  `file_common_bytes` bigint NOT NULL DEFAULT '0',
  `qa_bytes` bigint NOT NULL DEFAULT '0',
  PRIMARY KEY (`username`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='utf8_unicode_ci'