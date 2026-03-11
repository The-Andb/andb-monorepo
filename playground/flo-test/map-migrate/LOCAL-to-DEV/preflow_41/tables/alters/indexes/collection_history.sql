ALTER TABLE `collection_history`
ADD UNIQUE KEY `unq_user_id_and_created_date` (`collection_activity_id`,`created_date`),
ADD UNIQUE KEY `unq_user_id_and_updated_date` (`collection_activity_id`,`updated_date`);