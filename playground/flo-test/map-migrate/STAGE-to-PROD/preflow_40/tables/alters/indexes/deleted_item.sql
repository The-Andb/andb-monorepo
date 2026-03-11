ALTER TABLE `deleted_item`
ADD KEY `idx_created_date` (`created_sec`),
ADD KEY `unq_on_user_id_and_item_id_and_item_type` (`user_id`,`item_type`,`item_id`,`created_sec`),
ADD KEY `unq_on_user_id_and_item_uid_and_item_type` (`user_id`,`item_type`,`item_uid`,`created_sec`),
ADD KEY `idx_user_type_created` (`user_id`,`item_type`,`created_sec`),
ADD KEY `idx_id` (`id`),
ADD KEY `idx_user_id_and_type` (`user_id`,`item_type`),
ADD KEY `idx_user_type_created_updated` (`user_id`,`item_type`,`created_sec`,`updated_date`,`id`),
DROP INDEX `idx_user_id`,
DROP INDEX `idx_updated_date`,
DROP INDEX `unq_on_user_id_and_item_id_and_item_uid_and_item_type`;