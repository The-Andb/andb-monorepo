ALTER TABLE `helper_article_images`
ADD COLUMN `platform` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL AFTER `created_at`;