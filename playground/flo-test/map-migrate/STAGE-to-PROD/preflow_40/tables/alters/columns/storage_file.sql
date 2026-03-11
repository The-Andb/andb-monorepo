ALTER TABLE `storage_file`
ADD COLUMN `is_private` tinyint(1) DEFAULT '0' AFTER `created_by`;