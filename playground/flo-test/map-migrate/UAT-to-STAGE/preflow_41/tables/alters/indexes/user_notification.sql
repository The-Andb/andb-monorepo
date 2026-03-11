ALTER TABLE `user_notification`
ADD KEY `index_for_case_not_exist_modifiled` (`user_id`,`is_active`,`created_date`) USING BTREE,
ADD KEY `user_notification_user_id_IDX` (`user_id`,`updated_date`,`is_active`) USING BTREE;