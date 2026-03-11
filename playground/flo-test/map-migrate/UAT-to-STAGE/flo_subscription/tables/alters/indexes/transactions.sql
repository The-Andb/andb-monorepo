ALTER TABLE `transactions`
ADD UNIQUE KEY `uniq_with_sha` (`created_year`,`uniq_key_sha`);