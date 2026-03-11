ALTER TABLE `principals`
MODIFY COLUMN `uri` varchar(200) COLLATE utf8mb3_unicode_ci NOT NULL,
MODIFY COLUMN `email` varchar(80) COLLATE utf8mb3_unicode_ci,
MODIFY COLUMN `displayname` varchar(80) COLLATE utf8mb3_unicode_ci,
MODIFY COLUMN `vcardurl` varchar(255) COLLATE utf8mb3_unicode_ci;