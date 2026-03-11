ALTER TABLE `collection_activity`
ADD KEY `idx_user_id_and_collection_id` (`user_id`,`collection_id`);