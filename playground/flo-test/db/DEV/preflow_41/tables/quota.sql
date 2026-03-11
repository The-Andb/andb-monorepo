CREATE TABLE `quota` (
  `username` varchar(255) NOT NULL,
  `bytes` bigint NOT NULL DEFAULT '0',
  `messages` int NOT NULL DEFAULT '0',
  `cal_bytes` bigint NOT NULL DEFAULT '0',
  `card_bytes` bigint NOT NULL DEFAULT '0',
  `file_bytes` bigint NOT NULL DEFAULT '0',
  `num_sent` int NOT NULL DEFAULT '0',
  `file_common_bytes` bigint NOT NULL DEFAULT '0',
  `qa_bytes` bigint NOT NULL DEFAULT '0',
  `file_comment_bytes` bigint NOT NULL DEFAULT '0',
  `file_chat_bytes` bigint NOT NULL DEFAULT '0',
  PRIMARY KEY (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COMMENT='utf8_unicode_ci'