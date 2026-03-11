ALTER TABLE `collection_comment`
ADD COLUMN `linked_object_time` double(13,3) NOT NULL DEFAULT '0.000' AFTER `content_marked`;