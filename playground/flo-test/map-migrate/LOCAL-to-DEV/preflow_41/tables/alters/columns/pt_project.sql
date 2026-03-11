ALTER TABLE `pt_project`
MODIFY COLUMN `status` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci,
MODIFY COLUMN `week_start_day` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci,
MODIFY COLUMN `point_scale` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci,
MODIFY COLUMN `description` text CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci,
MODIFY COLUMN `project_type` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci,
MODIFY COLUMN `start_date` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci,
MODIFY COLUMN `uid` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci;