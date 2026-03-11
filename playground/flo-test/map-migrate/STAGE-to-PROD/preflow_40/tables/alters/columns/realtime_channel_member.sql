ALTER TABLE `realtime_channel_member`
ADD COLUMN `notification_chat` tinyint(1) NOT NULL DEFAULT '2' AFTER `channel_key`,
ADD COLUMN `notification_call` tinyint(1) NOT NULL DEFAULT '1' AFTER `notification_chat`;