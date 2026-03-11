ALTER TABLE `emoji_reaction`
ADD COLUMN `channel_id` bigint DEFAULT NULL AFTER `updated_date`;