ALTER TABLE `collection_notification`
ADD COLUMN `tag_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT '' AFTER `content`;