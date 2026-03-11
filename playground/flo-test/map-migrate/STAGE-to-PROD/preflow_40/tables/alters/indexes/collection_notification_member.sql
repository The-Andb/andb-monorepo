ALTER TABLE `collection_notification_member`
ADD KEY `idx_cnm_active_access` (`member_user_id`,`is_active`,`access`);