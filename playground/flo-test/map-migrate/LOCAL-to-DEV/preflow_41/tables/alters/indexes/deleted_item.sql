ALTER TABLE `deleted_item`
ADD KEY `idx_on_user_id_and_item_id_and_item_type` (`user_id`,`item_id`,`item_type`) USING BTREE,
ADD KEY `idx_on_user_id_and_item_type_and_updated_date` (`user_id`,`item_type`,`updated_date`) USING BTREE;