ALTER TABLE `conference_non_user`
ADD FULLTEXT KEY `conference_non_user_external_attendee_IDX` (`external_attendee`,`join_token`);