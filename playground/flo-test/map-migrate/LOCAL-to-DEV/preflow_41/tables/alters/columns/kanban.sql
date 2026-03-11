ALTER TABLE `kanban`
ADD COLUMN `hidden` int DEFAULT '0' AFTER `updated_date`;