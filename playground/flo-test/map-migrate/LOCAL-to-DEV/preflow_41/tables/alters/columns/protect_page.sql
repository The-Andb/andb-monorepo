ALTER TABLE `protect_page`
MODIFY COLUMN `verify_code` text COLLATE utf8mb3_unicode_ci NOT NULL,
MODIFY COLUMN `checksum` varchar(128) COLLATE utf8mb3_unicode_ci COMMENT 'MD5 of verify_code';