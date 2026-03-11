ALTER TABLE `realtime_message`
DROP INDEX `idx_uid`,
DROP INDEX `idx_to_channel`,
DROP INDEX `idx_type_and_uid`,
DROP INDEX `idx_type_migrate`;