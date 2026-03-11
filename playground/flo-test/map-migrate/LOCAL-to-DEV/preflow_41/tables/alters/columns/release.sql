ALTER TABLE `release`
MODIFY COLUMN `version` varchar(25) CHARACTER SET utf8mb3 NOT NULL DEFAULT '' COMMENT 'Version Flo app released',
MODIFY COLUMN `checksum` varchar(200) CHARACTER SET utf8mb3 NOT NULL DEFAULT '' COMMENT 'It is string and it will be hashed by client side';