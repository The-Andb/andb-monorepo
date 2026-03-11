ALTER TABLE `pt_project_epic`
MODIFY COLUMN `name` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci,
MODIFY COLUMN `project_uid` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci;