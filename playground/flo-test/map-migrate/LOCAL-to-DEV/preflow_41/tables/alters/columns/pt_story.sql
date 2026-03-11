ALTER TABLE `pt_story`
MODIFY COLUMN `uid` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
MODIFY COLUMN `name` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci,
MODIFY COLUMN `type` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci,
MODIFY COLUMN `description` text CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci,
MODIFY COLUMN `current_state` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci,
MODIFY COLUMN `url` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci;