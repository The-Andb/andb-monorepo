CREATE FUNCTION `OTE_updateChannelId4SharedCollection`() RETURNS INT
BEGIN
    DECLARE no_more_rows        boolean;
    DECLARE nCount              INT DEFAULT 0;
    DECLARE nCollectionID       BIGINT(20) DEFAULT 0;
    DECLARE nChannelID          BIGINT(20) DEFAULT 0;
    DECLARE nReturn             BIGINT(20) DEFAULT 0;
   
    DECLARE usr_cursor CURSOR FOR
    # Start of: main script;
   -- pnUserId, nchannelId, pvEmail, pvEmail, 1, pvTitle
  SELECT co.id, cc.id
      FROM collection co
      JOIN conference_channel cc ON (co.id = cc.collection_id)
      WHERE co.channel_id = 0
      ;
       -- LIMIT 10000
    # END of: main script
   DECLARE CONTINUE handler FOR NOT found SET no_more_rows = TRUE;
   --
   OPEN usr_cursor;
   usr_loop: LOOP
     -- start LOOP usr_cursor
     FETCH usr_cursor 
      INTO nCollectionID, nChannelID;
     -- stop LOOP WHEN no_more_rows
     IF (no_more_rows) THEN
       CLOSE usr_cursor;
       LEAVE usr_loop;
     END IF;
     # main UPDATE
     UPDATE collection co
        SET co.channel_id = nChannelID
      WHERE co.id = nCollectionID;
     --
     SET nCount = nCount + 1;
      # main UPDATE
     --
   END LOOP usr_loop;
   --
RETURN nCount;
END