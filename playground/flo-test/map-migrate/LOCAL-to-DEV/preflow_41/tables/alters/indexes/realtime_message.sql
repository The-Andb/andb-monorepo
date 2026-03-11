ALTER TABLE `realtime_message`
ADD KEY `idx_uid` (`uid`) USING BTREE,
ADD KEY `idx_to_channel` (`to_channel`),
ADD KEY `idx_type_and_uid` (`type`,`uid`);