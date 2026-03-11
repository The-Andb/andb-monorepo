ALTER TABLE `conference_member`
ADD COLUMN `last_missed_call` double(13,3) NOT NULL AFTER `last_seen_call`,
ADD COLUMN `notification_chat` tinyint(1) NOT NULL DEFAULT '2' AFTER `missed_calls`,
ADD COLUMN `notification_call` tinyint(1) NOT NULL DEFAULT '1' AFTER `notification_chat`;