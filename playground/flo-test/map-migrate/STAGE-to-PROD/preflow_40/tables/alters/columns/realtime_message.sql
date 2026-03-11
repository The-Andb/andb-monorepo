ALTER TABLE `realtime_message`
ADD COLUMN `linked_object_time` double(13,3) NOT NULL DEFAULT '0.000' AFTER `deleted_message_type`;