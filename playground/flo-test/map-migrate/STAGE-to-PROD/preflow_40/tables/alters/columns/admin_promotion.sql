ALTER TABLE `admin_promotion`
ADD COLUMN `promotion_type` tinyint NOT NULL COMMENT '1=''register_based'', 2=''coupon_based'', 3=''referral_based''' AFTER `description`,
ADD COLUMN `promotion_value` varchar(100) DEFAULT NULL AFTER `promotion_type`,
ADD COLUMN `priority` tinyint NOT NULL DEFAULT '-1' COMMENT 'smaller number means higher priority' AFTER `promotion_value`,
ADD COLUMN `is_active` tinyint NOT NULL DEFAULT '1' AFTER `priority`;