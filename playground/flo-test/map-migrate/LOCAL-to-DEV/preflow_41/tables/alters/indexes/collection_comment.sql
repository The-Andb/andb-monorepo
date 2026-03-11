ALTER TABLE `collection_comment`
ADD UNIQUE KEY `unq_user_id_and_updated_date` (`user_id`,`collection_activity_id`,`updated_date`),
ADD UNIQUE KEY `unq_user_id_and_created_date` (`collection_activity_id`,`created_date`);