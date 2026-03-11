ALTER TABLE `pt_project_tag`
MODIFY COLUMN `project_uid` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci,
MODIFY COLUMN `name` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci;