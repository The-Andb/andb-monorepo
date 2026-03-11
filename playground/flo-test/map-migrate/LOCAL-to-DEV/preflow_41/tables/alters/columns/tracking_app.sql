ALTER TABLE `tracking_app`
MODIFY COLUMN `name` varchar(255) COLLATE utf8mb3_unicode_ci,
MODIFY COLUMN `app_version` varchar(255) COLLATE utf8mb3_unicode_ci,
MODIFY COLUMN `flo_version` varchar(255) COLLATE utf8mb3_unicode_ci,
MODIFY COLUMN `app_id` varchar(255) COLLATE utf8mb3_unicode_ci,
MODIFY COLUMN `build_number` varchar(45) COLLATE utf8mb3_unicode_ci;