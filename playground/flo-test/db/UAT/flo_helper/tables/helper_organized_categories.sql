CREATE TABLE `helper_organized_categories` (
  `id` int NOT NULL AUTO_INCREMENT,
  `category_uid` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Unique identifier for the category (UUID)',
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Category name',
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Category description',
  `created_by` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'User who created this category',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Category creation timestamp',
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Category last update timestamp',
  PRIMARY KEY (`id`),
  UNIQUE KEY `category_uid` (`category_uid`),
  KEY `idx_category_uid` (`category_uid`),
  KEY `idx_name` (`name`),
  KEY `idx_created_by` (`created_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Organized categories created by users'