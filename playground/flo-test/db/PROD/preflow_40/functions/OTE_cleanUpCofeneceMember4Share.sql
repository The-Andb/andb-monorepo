CREATE FUNCTION `OTE_cleanUpCofeneceMember4Share`(
pnCollectionId BIGINT(20)
,pnChannelId BIGINT(20)
,pnUserID  BIGINT(20)) RETURNS INT
BEGIN
    DECLARE no_more_rows        boolean;
    DECLARE nCount              INT DEFAULT 0;
    DECLARE nCMID          BIGINT(20) DEFAULT 0;
    DECLARE nRCMID          BIGINT(20) DEFAULT 0;
    DECLARE nReturn             BIGINT(20) DEFAULT 0;
   
    
    DECLARE usr_cursor CURSOR FOR
    # Start of: main script;
   -- pnUserId, nchannelId, pvEmail, pvEmail, 1, pvTitle
  SELECT cm.id
    FROM conference_member cm
    JOIN conference_channel cc ON (cm.channel_id = cc.id)
    JOIN collection co ON (co.id = cc.collection_id AND co.type = 3)
LEFT JOIN collection_shared_member csm ON (csm.shared_email = cm.email AND co.id = csm.collection_id)
    WHERE (pnCollectionId IS NULL OR co.id = pnCollectionId)
      AND (pnChannelId IS NULL OR cc.id = pnChannelId)
      AND (pnUserID IS NULL OR co.user_id = pnUserID)
      AND co.user_id <> cm.user_id
      AND (csm.id IS NULL OR csm.shared_status IN (0,2,3,4) OR csm.access=1)
      ;
       -- LIMIT 10000
    # END of: main script
   DECLARE CONTINUE handler FOR NOT found SET no_more_rows = TRUE;
   --
   OPEN usr_cursor;
   usr_loop: LOOP
     -- start LOOP usr_cursor
     FETCH usr_cursor 
      INTO nCMID;
     -- stop LOOP WHEN no_more_rows
     IF (no_more_rows) THEN
       CLOSE usr_cursor;
       LEAVE usr_loop;
     END IF;
     # main UPDATE
     -- DELETE conference_member
     DELETE FROM conference_member WHERE id = nCMID;
     
     -- DELETE realtime_member
     SELECT ifnull(max(rcm.id), 0)
       INTO nRCMID
       FROM conference_member cm
       JOIN conference_channel cc ON (cm.channel_id = cc.id)
  LEFT JOIN realtime_channel_member rcm ON (rcm.email = cm.email) 
       JOIN realtime_channel rc ON (rc.id = rcm.channel_id AND rc.internal_channel_id = cc.id AND rc.type = 'CONFERENCE')
      WHERE cm.id = nCMID;
    --
    IF nRCMID > 0 THEN
     DELETE FROM realtime_channel_member WHERE id = nRCMID;
     END IF;
    SELECT LAST_INSERT_ID() INTO nReturn;
     --
     SET nCount = nCount + 1;
      # main UPDATE
     --
   END LOOP usr_loop;
   --
RETURN nCount;
END