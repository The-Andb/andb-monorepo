ALTER TABLE `user`
CHANGE COLUMN username username varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
CHANGE COLUMN password password varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
CHANGE COLUMN password2 password2 varchar(255) DEFAULT NULL;