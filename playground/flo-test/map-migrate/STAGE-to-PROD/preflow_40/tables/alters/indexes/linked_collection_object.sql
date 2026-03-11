ALTER TABLE `linked_collection_object`
ADD KEY `idx_user_id_trashed` (`id`,`user_id`,`is_trashed`);