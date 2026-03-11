ALTER TABLE `storage_colla_document_history`
MODIFY COLUMN `doc_uid` varchar(200) COLLATE utf8mb3_unicode_ci,
MODIFY COLUMN `change` text COLLATE utf8mb3_unicode_ci,
MODIFY COLUMN `change_by` varchar(100) COLLATE utf8mb3_unicode_ci;