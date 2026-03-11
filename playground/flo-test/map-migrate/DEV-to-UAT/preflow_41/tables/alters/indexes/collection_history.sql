ALTER TABLE `collection_history`
ADD KEY `collection_history_collection_id_updated_date_IDX` (`collection_id`,`updated_date`) USING BTREE;