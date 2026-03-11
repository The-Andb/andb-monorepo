ALTER TABLE `collection_history`
ADD COLUMN `tag_name` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL DEFAULT '' AFTER `content`;