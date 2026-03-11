ALTER TABLE `storage_colla_document_operation`
MODIFY COLUMN `uid` varchar(255) COLLATE utf8mb3_unicode_ci NOT NULL,
MODIFY COLUMN `document_version_uid` varchar(255) COLLATE utf8mb3_unicode_ci;