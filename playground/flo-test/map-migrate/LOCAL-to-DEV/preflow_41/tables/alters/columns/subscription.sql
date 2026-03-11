ALTER TABLE `subscription`
MODIFY COLUMN `id` varchar(255) COLLATE utf8mb3_unicode_ci NOT NULL DEFAULT '',
MODIFY COLUMN `name` varchar(255) COLLATE utf8mb3_unicode_ci NOT NULL DEFAULT '',
MODIFY COLUMN `description` varchar(255) COLLATE utf8mb3_unicode_ci NOT NULL DEFAULT '';