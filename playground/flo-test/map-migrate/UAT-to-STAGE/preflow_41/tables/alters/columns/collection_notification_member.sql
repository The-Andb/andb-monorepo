ALTER TABLE `collection_notification_member`
ADD COLUMN `last_seen_chat` double(13,3) NOT NULL DEFAULT '0.000' AFTER `fk_csm_id`,
ADD COLUMN `last_seen_call` double(13,3) NOT NULL DEFAULT '0.000' AFTER `last_seen_chat`,
ADD COLUMN `cnm_id` int NOT NULL AFTER `partition_group`,
MODIFY COLUMN `owner_user_id` varchar(255) CHARACTER SET latin1 COLLATE latin1_swedish_ci;