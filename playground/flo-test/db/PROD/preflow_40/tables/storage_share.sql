CREATE TABLE `storage_share` (
  `id` int NOT NULL AUTO_INCREMENT,
  `file_uid` varchar(200) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `user` varchar(300) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `channel_id` bigint DEFAULT NULL,
  `channel` varchar(200) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `shared_by` varchar(200) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `channel_type` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `shared_with_role` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'viewer: role has read and access file info\r\neditor: role has  viewer role permissons and write permission\r\nadmin: role has editor role permissions and delete permission',
  `created_date` double(13,3) DEFAULT NULL,
  `updated_date` double(13,3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `share_UN` (`file_uid`,`channel_id`,`channel_type`),
  UNIQUE KEY `share_UN_USER` (`file_uid`,`user`),
  KEY `storage_share_user_IDX` (`user`) USING BTREE,
  KEY `storage_share_channel_id_IDX` (`channel_id`,`channel_type`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci