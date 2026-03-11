ALTER TABLE `collection_shared_last_modified`
ADD COLUMN `user_id` bigint DEFAULT '0' AFTER `updated_date`;