ALTER TABLE `send_mail`
MODIFY COLUMN `to_email` varchar(255) COLLATE utf8mb3_unicode_ci NOT NULL DEFAULT '',
MODIFY COLUMN `subject` varchar(255) COLLATE utf8mb3_unicode_ci NOT NULL DEFAULT '',
MODIFY COLUMN `template` varchar(255) COLLATE utf8mb3_unicode_ci NOT NULL DEFAULT '',
MODIFY COLUMN `upgrade_to` varchar(255) COLLATE utf8mb3_unicode_ci NOT NULL DEFAULT '',
MODIFY COLUMN `expired` varchar(255) COLLATE utf8mb3_unicode_ci NOT NULL DEFAULT '';