ALTER TABLE `pt_story_blocker`
MODIFY COLUMN `story_uid` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci,
MODIFY COLUMN `description` text CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci;