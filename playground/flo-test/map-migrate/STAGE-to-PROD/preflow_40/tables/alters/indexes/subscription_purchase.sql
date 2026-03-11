ALTER TABLE `subscription_purchase`
ADD KEY `idx_on_end_date` (`end_date`),
ADD KEY `idx_on_start_date` (`start_date`);