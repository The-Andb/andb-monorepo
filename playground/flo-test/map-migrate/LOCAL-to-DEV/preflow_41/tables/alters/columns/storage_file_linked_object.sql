ALTER TABLE `storage_file_linked_object`
MODIFY COLUMN `file_uid` varchar(200) COLLATE utf8mb3_unicode_ci NOT NULL,
MODIFY COLUMN `object_uid` varchar(200) COLLATE utf8mb3_unicode_ci,
MODIFY COLUMN `linked_by` varchar(200) COLLATE utf8mb3_unicode_ci;