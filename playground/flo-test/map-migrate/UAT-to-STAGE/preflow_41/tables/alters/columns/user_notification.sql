ALTER TABLE `user_notification`
ADD COLUMN `cnm_id` bigint NOT NULL DEFAULT '0' AFTER `is_active`;