ALTER TABLE `collection_comment`
ADD COLUMN `collection_id` bigint NOT NULL DEFAULT '-1' AFTER `mention_all`;