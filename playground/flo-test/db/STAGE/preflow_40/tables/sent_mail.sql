CREATE TABLE `sent_mail` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `message_id` text COLLATE utf8mb4_unicode_ci,
  `predicted_next_uid` int DEFAULT NULL,
  `email_subject` text COLLATE utf8mb4_unicode_ci,
  `link_item_id` text COLLATE utf8mb4_unicode_ci,
  `filing_item_id` int DEFAULT NULL,
  `tracking_period` int DEFAULT NULL,
  `sending_status` int DEFAULT NULL,
  `account` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC