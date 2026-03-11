CREATE TABLE `pt_user_mapping` (
  `id` int NOT NULL AUTO_INCREMENT,
  `pt_email` varchar(255) NOT NULL,
  `flo_email` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `flo_user_id` varchar(45) DEFAULT NULL,
  `env` enum('DEV','UAT','STAGE','PROD') NOT NULL,
  `created_date` double DEFAULT NULL,
  `updated_date` double DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `unique` (`pt_email`,`env`),
  KEY `idx_pt_mail` (`pt_email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci