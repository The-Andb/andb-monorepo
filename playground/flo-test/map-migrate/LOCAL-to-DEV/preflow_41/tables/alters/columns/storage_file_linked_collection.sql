ALTER TABLE `storage_file_linked_collection`
MODIFY COLUMN `collection_type` varchar(100) COLLATE utf8mb3_unicode_ci NOT NULL,
MODIFY COLUMN `file_uid` varchar(200) COLLATE utf8mb3_unicode_ci NOT NULL,
MODIFY COLUMN `linked_by` varchar(200) COLLATE utf8mb3_unicode_ci;