ALTER TABLE `realtime_message`
MODIFY COLUMN `parent_uid` varchar(100),
MODIFY COLUMN `message_marked` text;