ALTER TABLE `collection_notification`
ADD KEY `collection_notification_actor_IDX` (`actor`) USING BTREE,
ADD KEY `idx_object_uid` (`object_uid`),
ADD KEY `idx_cn_created_collection_channel` (`created_date`,`collection_id`,`channel_id`,`user_id`),
ADD KEY `collection_notification_created_date_IDX` (`created_date`,`channel_id`) USING BTREE,
ADD KEY `collection_created_date_IDX` (`created_date`,`collection_id`) USING BTREE,
ADD KEY `collection_notification_user_id_IDX` (`user_id`,`created_date`) USING BTREE,
ADD KEY `idx_channel_collection_action` (`collection_id`,`action`,`channel_id`),
ADD KEY `idx_sobject_type` (`sobject_type`),
ADD KEY `idx_sobject_uid` (`sobject_uid`);