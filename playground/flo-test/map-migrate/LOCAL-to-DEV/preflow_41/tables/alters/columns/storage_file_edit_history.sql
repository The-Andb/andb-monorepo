ALTER TABLE `storage_file_edit_history`
MODIFY COLUMN `file_uid` varchar(255) COLLATE utf8mb3_unicode_ci NOT NULL,
MODIFY COLUMN `user` varchar(100) COLLATE utf8mb3_unicode_ci NOT NULL,
MODIFY COLUMN `edit_details` text COLLATE utf8mb3_unicode_ci;