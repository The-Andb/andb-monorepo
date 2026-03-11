ALTER TABLE `release`
ADD COLUMN `upload_type` enum('0','1') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT '0' AFTER `release_status`,
MODIFY COLUMN `release_status` enum('0','1','2','3') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT 'Value: \n  * 0: admin-upload\n  * 1: Media Upload';