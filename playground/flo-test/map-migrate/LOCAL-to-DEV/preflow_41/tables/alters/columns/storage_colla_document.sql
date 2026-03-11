ALTER TABLE `storage_colla_document`
MODIFY COLUMN `uid` varchar(255) COLLATE utf8mb3_unicode_ci NOT NULL,
MODIFY COLUMN `name` varchar(255) COLLATE utf8mb3_unicode_ci NOT NULL,
MODIFY COLUMN `object_uid` varchar(255) COLLATE utf8mb3_unicode_ci;