ALTER TABLE `storage_file_edit_session`
MODIFY COLUMN `user` varchar(200) COLLATE utf8mb3_unicode_ci NOT NULL,
MODIFY COLUMN `edit_token` varchar(255) COLLATE utf8mb3_unicode_ci NOT NULL,
MODIFY COLUMN `temp_file_path` varchar(255) COLLATE utf8mb3_unicode_ci NOT NULL,
MODIFY COLUMN `file_uid` varchar(255) COLLATE utf8mb3_unicode_ci;