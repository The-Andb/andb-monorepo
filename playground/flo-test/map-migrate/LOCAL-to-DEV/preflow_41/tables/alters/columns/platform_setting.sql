ALTER TABLE `platform_setting`
ADD COLUMN `incoming_call` tinyint(1) NOT NULL DEFAULT '0' COMMENT '0 - Every one (default)\n1 - My Contacts Only\n2 - VIP only' AFTER `app_version`,
ADD COLUMN `incoming_mail` tinyint(1) NOT NULL DEFAULT '0' COMMENT '0 - Every one (default)\n1 - My Contacts Only \n 2 -VIP only ' AFTER `incoming_call`,
ADD COLUMN `filter_chat` tinyint(1) NOT NULL DEFAULT '0' COMMENT '0 - All Messages (default)\n1 - Mention for Me Only' AFTER `incoming_mail`,
MODIFY COLUMN `device_uid` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '';