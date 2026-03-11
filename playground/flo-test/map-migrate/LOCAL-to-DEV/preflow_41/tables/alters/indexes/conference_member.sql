ALTER TABLE `conference_member`
ADD KEY `conference_member_vip_IDX` (`vip`) USING BTREE,
ADD FULLTEXT KEY `conference_member_member_arn_IDX` (`member_arn`);