CREATE TABLE `helper_article_images` (
  `id` int NOT NULL AUTO_INCREMENT,
  `image_uid` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Unique identifier for the image (UUID)',
  `article_uid` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Article unique identifier this image belongs to',
  `file_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'UUID filename stored on disk',
  `url` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Public URL to access the image',
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'AI-generated description of the image',
  `alt` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Alt text for the image',
  `mime_type` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'MIME type of the image',
  `file_size` bigint NOT NULL COMMENT 'File size in bytes',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Image creation timestamp',
  `platform` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `image_uid` (`image_uid`),
  KEY `idx_article_uid` (`article_uid`) USING BTREE,
  KEY `idx_image_uid` (`image_uid`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Article images metadata'