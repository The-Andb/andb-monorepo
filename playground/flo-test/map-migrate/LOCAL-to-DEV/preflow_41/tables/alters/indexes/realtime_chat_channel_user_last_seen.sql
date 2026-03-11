ALTER TABLE `realtime_chat_channel_user_last_seen`
ADD KEY `idx_email` (`email`),
ADD KEY `idx_revoke` (`disabled`);