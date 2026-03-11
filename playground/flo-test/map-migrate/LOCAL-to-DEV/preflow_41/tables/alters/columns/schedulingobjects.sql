ALTER TABLE `schedulingobjects`
MODIFY COLUMN `principaluri` varchar(255) COLLATE utf8mb3_unicode_ci,
MODIFY COLUMN `uri` varchar(200) COLLATE utf8mb3_unicode_ci,
MODIFY COLUMN `etag` varchar(32) COLLATE utf8mb3_unicode_ci;