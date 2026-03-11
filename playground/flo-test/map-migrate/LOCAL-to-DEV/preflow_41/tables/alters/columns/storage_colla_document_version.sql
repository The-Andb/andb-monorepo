ALTER TABLE `storage_colla_document_version`
ADD COLUMN `version` int DEFAULT NULL AFTER `metadata`,
ADD COLUMN `base_length` double DEFAULT NULL AFTER `version`,
MODIFY COLUMN `uid` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
MODIFY COLUMN `document_uid` varchar(255) COLLATE utf8mb3_unicode_ci,
MODIFY COLUMN `metadata` text COLLATE utf8mb3_unicode_ci,
MODIFY COLUMN `name` varchar(100) COLLATE utf8mb3_unicode_ci;