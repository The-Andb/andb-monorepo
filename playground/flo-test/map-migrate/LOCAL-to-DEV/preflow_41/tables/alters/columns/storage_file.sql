ALTER TABLE `storage_file`
ADD COLUMN `storage` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL AFTER `uid`,
ADD COLUMN `storage_mtime` bigint DEFAULT NULL AFTER `mtime`,
ADD COLUMN `storage_path` varchar(500) COLLATE utf8mb4_general_ci DEFAULT NULL AFTER `mimetype`;