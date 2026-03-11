ALTER TABLE `realtime_channel_member`
ADD KEY `idx_channel_name` (`channel_name`,`email`) USING BTREE;