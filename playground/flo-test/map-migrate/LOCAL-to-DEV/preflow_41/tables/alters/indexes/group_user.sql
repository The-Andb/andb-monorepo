ALTER TABLE `group_user`
ADD UNIQUE KEY `uniq_on_groupId_and_groupName_and_userId_and_username` (`group_name`,`username`,`user_id`,`group_id`) USING BTREE,
ADD KEY `idx_username` (`username`);