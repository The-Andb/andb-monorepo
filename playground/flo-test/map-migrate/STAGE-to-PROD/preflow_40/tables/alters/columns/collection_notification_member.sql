ALTER TABLE `collection_notification_member`
ADD COLUMN `access` tinyint(1) NOT NULL DEFAULT '2' AFTER `member_email`;