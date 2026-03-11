ALTER TABLE `subscription_purchase`
MODIFY COLUMN `sub_id` varchar(255) COLLATE utf8mb3_unicode_ci NOT NULL DEFAULT '',
MODIFY COLUMN `transaction_id` varchar(500) COLLATE utf8mb3_unicode_ci NOT NULL DEFAULT '';