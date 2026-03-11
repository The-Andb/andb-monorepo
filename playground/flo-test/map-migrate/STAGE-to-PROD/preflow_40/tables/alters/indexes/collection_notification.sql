ALTER TABLE `collection_notification`
ADD KEY `idx_cn_query` (`channel_id`,`collection_id`,`object_type`,`action`,`id`);