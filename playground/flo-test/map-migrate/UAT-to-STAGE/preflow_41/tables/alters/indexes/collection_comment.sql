ALTER TABLE `collection_comment`
ADD KEY `idx_collection_id` (`collection_id`),
ADD KEY `collection_comment_user_id_IDX` (`user_id`,`collection_id`,`updated_date`) USING BTREE;