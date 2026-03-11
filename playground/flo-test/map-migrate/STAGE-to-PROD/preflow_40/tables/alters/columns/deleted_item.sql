ALTER TABLE `deleted_item`
ADD COLUMN `created_sec` bigint GENERATED ALWAYS AS (floor(`created_date`)) STORED NOT NULL AFTER `updated_date`,
MODIFY COLUMN `item_id` bigint COLLATE latin1_swedish_ci;