ALTER TABLE `group_user`
DROP INDEX `uniq_on_groupId_and_groupName_and_userId_and_username`,
DROP INDEX `idx_username`;