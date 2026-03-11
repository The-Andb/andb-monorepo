CREATE TABLE `pt_person` (
  `id` int NOT NULL,
  `kind` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `initials` varchar(255) NOT NULL,
  `username` varchar(255) NOT NULL,
  `created_date` double NOT NULL,
  `updated_date` double NOT NULL,
  PRIMARY KEY (`id`),
  KEY `unique` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci