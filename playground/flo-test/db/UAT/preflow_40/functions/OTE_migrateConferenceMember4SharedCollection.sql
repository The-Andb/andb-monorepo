CREATE FUNCTION `OTE_migrateConferenceMember4SharedCollection`(
pnCollectionId BIGINT(20)
,pnChannelId BIGINT(20)
,pnUserID  BIGINT(20)) RETURNS INT
BEGIN
    DECLARE no_more_rows        boolean;
    DECLARE nCount              INT DEFAULT 0;
    DECLARE nChannelId          BIGINT(20) DEFAULT 0;
    DECLARE nReturn             BIGINT(20) DEFAULT 0;
    DECLARE nUserID             BIGINT(20);
    DECLARE pvUid               VARBINARY(1000);
    DECLARE vTitle              VARCHAR(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    DECLARE vEmail              VARCHAR(255);
    DECLARE nCreatedDate        DOUBLE(13,3);
    DECLARE nUpdatedDate        DOUBLE(13,3);
    
    DECLARE usr_cursor CURSOR FOR
    # Start of: main script;
   -- pnUserId, nchannelId, pvEmail, pvEmail, 1, pvTitle
   SELECT csm.member_user_id, cc.id, csm.shared_email, co.name, csm.created_date, csm.updated_date
     FROM collection_shared_member csm
     JOIN collection co ON (csm.collection_id = co.id)
     JOIN conference_channel cc ON (co.id = cc.collection_id)
LEFT JOIN conference_member cm ON (cc.id = cm.channel_id AND csm.shared_email = cm.email)
    WHERE (pnCollectionId IS NULL OR co.id = pnCollectionId)
      AND (pnChannelId IS NULL OR cc.id = pnChannelId)
      AND (pnUserID IS NULL OR co.user_id = pnUserID)
      AND co.type = 3
      AND co.is_trashed = 0
      AND csm.access IN (0, 2)
      AND csm.shared_status = 1
      AND cm.id IS NULL
      ;
       -- LIMIT 10000
    # END of: main script
   DECLARE CONTINUE handler FOR NOT found SET no_more_rows = TRUE;
   --
   OPEN usr_cursor;
   usr_loop: LOOP
     -- start LOOP usr_cursor
     FETCH usr_cursor 
      INTO nUserID, nChannelId, vEmail, vTitle, nCreatedDate, nUpdatedDate;
     -- stop LOOP WHEN no_more_rows
     IF (no_more_rows) THEN
       CLOSE usr_cursor;
       LEAVE usr_loop;
     END IF;
     # main UPDATE
     INSERT INTO conference_member
      (user_id, channel_id, email, created_by, is_creator, title,
       description, avatar, vip, view_chat_history, chat_url, join_time, created_date, updated_date)
    VALUES
      (nUserID, nChannelId, vEmail, vEmail, 1, vTitle,
       NULL, NULL, 0, NULL, '', nCreatedDate, nCreatedDate, nUpdatedDate);
    -- ON DUPLICATE KEY UPDATE updated_date = unix_timestamp();
    SELECT LAST_INSERT_ID() INTO nReturn;
     --
     SET nCount = nCount + 1;
      # main UPDATE
     --
   END LOOP usr_loop;
   --
RETURN nCount;
END