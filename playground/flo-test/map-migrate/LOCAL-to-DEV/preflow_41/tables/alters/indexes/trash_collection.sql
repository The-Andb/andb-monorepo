ALTER TABLE `trash_collection`
ADD KEY `idx_on_obj_type_and_object_uid` (`object_type`,`object_uid`) USING BTREE,
ADD KEY `idx_on_object_uid_and_object_type` (`object_uid`,`object_type`);