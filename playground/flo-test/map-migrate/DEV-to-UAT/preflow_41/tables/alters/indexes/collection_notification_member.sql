ALTER TABLE `collection_notification_member`
ADD KEY `collection_notification_member_member_user_id_IDX` (`member_user_id`,`partition_group`) USING BTREE;