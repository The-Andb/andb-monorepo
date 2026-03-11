ALTER TABLE `realtime_chat_channel_user_last_seen`
ADD KEY `idx_last_msg_created` (`channel_last_message_created_date`) USING BTREE;