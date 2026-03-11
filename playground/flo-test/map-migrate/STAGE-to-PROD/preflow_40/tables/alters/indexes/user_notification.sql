ALTER TABLE `user_notification`
ADD KEY `idx_un_query` (`user_id`,`status`,`created_date`,`collection_notification_id`),
ADD KEY `idx_un_user_active_updated` (`user_id`,`is_active`,`updated_date`) USING BTREE,
ADD KEY `idx_un_cover` (`user_id`,`is_active`,`updated_date`,`collection_notification_id`,`has_mention`),
DROP INDEX `user_notification_user_id_IDX`;