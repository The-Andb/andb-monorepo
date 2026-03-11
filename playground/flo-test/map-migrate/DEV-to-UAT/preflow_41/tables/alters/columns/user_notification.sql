ALTER TABLE `user_notification`
MODIFY COLUMN `status` tinyint NOT NULL DEFAULT '0' COMMENT '0: Un-read\n\n1: Read\n\n2: Closed' COLLATE latin1_swedish_ci;