ALTER TABLE `user_notification`
ADD COLUMN `alert_duration` int DEFAULT '0' AFTER `has_mention`;