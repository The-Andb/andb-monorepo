ALTER TABLE `realtime_user_settings`
ADD UNIQUE KEY `realtime_settings_UN` (`email`,`name`);