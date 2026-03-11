ALTER TABLE `realtime_chat_channel_user_last_seen`
ADD COLUMN `channel_last_message_created_date` double(13,3) NOT NULL DEFAULT '0.000' AFTER `channel_last_message_uid`;