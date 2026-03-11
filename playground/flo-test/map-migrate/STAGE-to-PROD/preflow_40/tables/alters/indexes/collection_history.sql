ALTER TABLE `collection_history`
ADD KEY `collection_history_collection_id_IDX` (`collection_id`) USING BTREE,
ADD KEY `collection_history_collection_id_updated_date_IDX` (`collection_id`,`updated_date`) USING BTREE,
DROP INDEX `unq_user_id_and_created_date`,
DROP INDEX `unq_user_id_and_updated_date`;