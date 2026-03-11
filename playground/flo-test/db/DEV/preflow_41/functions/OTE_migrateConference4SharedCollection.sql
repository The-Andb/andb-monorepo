CREATE FUNCTION `OTE_migrateConference4SharedCollection`(
pnCollectionId BIGINT(20)
,pnUserID  BIGINT(20)) RETURNS INT
BEGIN
    DECLARE no_more_rows        boolean;
    DECLARE nCount              INT DEFAULT 0;
    DECLARE nChannelId          BIGINT(20) DEFAULT 0;
    DECLARE nReturn             BIGINT(20) DEFAULT 0;
    DECLARE nUserID             BIGINT(20);
    DECLARE nCollectionId       BIGINT(20);
    DECLARE pvUid               VARBINARY(1000);
    DECLARE vTitle              VARCHAR(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    DECLARE vEmail              VARCHAR(255);
    DECLARE nCreatedDate        DOUBLE(13,3);
    DECLARE nUpdatedDate        DOUBLE(13,3);
    
    DECLARE usr_cursor CURSOR FOR
    # Start of: main script;
   SELECT co.user_id, co.id, co.name, co.calendar_uri, co.created_date, co.updated_date, u.email
     FROM collection co
     JOIN user u ON (u.id = co.user_id)
LEFT JOIN conference_channel cc ON (co.id = cc.collection_id)
    WHERE (pnCollectionId IS NULL OR co.id = pnCollectionId)
      AND (pnUserID IS NULL OR co.user_id = pnUserID)
      AND co.type = 3
      AND co.is_trashed = 0
      AND cc.id IS NULL
      ;
       -- LIMIT 10000
    # END of: main script
   DECLARE CONTINUE handler FOR NOT found SET no_more_rows = TRUE;
   --
   OPEN usr_cursor;
   usr_loop: LOOP
     -- start LOOP usr_cursor
     FETCH usr_cursor 
      INTO nUserID, nCollectionId, vTitle, pvUid, nCreatedDate, nUpdatedDate, vEmail;
     -- stop LOOP WHEN no_more_rows
     IF (no_more_rows) THEN
       CLOSE usr_cursor;
       LEAVE usr_loop;
     END IF;
     # main UPDATE
     SET nChannelId = OTE_createChannel(nUserID,nCollectionId, pvUid, vEmail, vTitle, nCreatedDate, nUpdatedDate);
     -- CREATE conference member
     SET nReturn = OTE_migrateConferenceMember4SharedCollection(nCollectionId, nChannelId, pnUserID);
     -- CREATE realtime channel
     SET nReturn = OTE_migrateRealTimeChannel(nChannelId);
     -- CREATE realtime members
     SET nReturn = OTE_migrateRealTimeMember(nChannelId);
     --
     SET nCount = nCount + 1;
      # main UPDATE
     --
   END LOOP usr_loop;
   
   SET nReturn = OTE_updateFieldRealtimeChannel();
   --
RETURN nCount;
END