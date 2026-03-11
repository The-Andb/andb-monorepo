ALTER TABLE `subscription_purchase`
ADD COLUMN `start_date` double(13,3) NOT NULL DEFAULT '-1.000' AFTER `purchase_status`,
ADD COLUMN `end_date` double(13,3) NOT NULL DEFAULT '-1.000' AFTER `start_date`;