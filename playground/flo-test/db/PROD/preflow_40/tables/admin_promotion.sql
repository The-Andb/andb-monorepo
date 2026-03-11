CREATE TABLE `admin_promotion` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `allow_pre_signup` tinyint unsigned NOT NULL DEFAULT '0',
  `signup_type` enum('1','2','3','4','5') CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL DEFAULT '5' COMMENT '1: yearly pro, 2: monthly pro, 3: yearly premium, 4: monthly premium, 5: standard',
  `promotion_expired` double(13,3) NOT NULL DEFAULT '0.000',
  `description` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `created_date` double(13,3) NOT NULL,
  `updated_date` double(13,3) DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='utf8_unicode_ci'