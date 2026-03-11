ALTER TABLE `kanban`
ADD COLUMN `kanban_status` int NOT NULL DEFAULT '-1' AFTER `updated_date`,
MODIFY COLUMN `order_update_time` double(14,4) NOT NULL DEFAULT '0.0000' COLLATE latin1_swedish_ci,
MODIFY COLUMN `updated_date` double(14,4) NOT NULL DEFAULT '0.0000' COLLATE latin1_swedish_ci;