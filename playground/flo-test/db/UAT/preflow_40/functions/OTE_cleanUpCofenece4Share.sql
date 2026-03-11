CREATE FUNCTION `OTE_cleanUpCofenece4Share`() RETURNS INT
BEGIN
    DECLARE no_more_rows        boolean;
    DECLARE nCount              INT DEFAULT 0;
    DECLARE nChannelID          BIGINT(20);
    DECLARE nCollectionID       BIGINT(20);
    DECLARE nReturn             BIGINT(20);
    DECLARE isTrashed          TINYINT(2);
   
    
    DECLARE usr_cursor CURSOR FOR
    # Start of: main script;
   -- pnUserId, nchannelId, pvEmail, pvEmail, 1, pvTitle
   SELECT cc.id, cc.collection_id, co.is_trashed
     FROM conference_channel cc
LEFT JOIN collection co ON (cc.id = co.channel_id AND cc.collection_id = co.id)
    WHERE cc.collection_id IS NOT NULL
      AND  cc.collection_id > 0
      AND (co.id IS NULL OR 
         (co.is_trashed <> cc.is_trashed)
      );
       -- LIMIT 10000
    # END of: main script
   DECLARE CONTINUE handler FOR NOT found SET no_more_rows = TRUE;
   --
   OPEN usr_cursor;
   usr_loop: LOOP
     -- start LOOP usr_cursor
     FETCH usr_cursor 
      INTO nChannelID, nCollectionID, isTrashed;
     -- stop LOOP WHEN no_more_rows
     IF (no_more_rows) THEN
       CLOSE usr_cursor;
       LEAVE usr_loop;
     END IF;
     # main UPDATE
     -- DELETE conference_member
     UPDATE conference_channel cc
        SET cc.is_trashed = isTrashed
      WHERE cc.id = nChannelID;
       --
       SELECT ifnull(max(co.id), 0)
         INTO nReturn
         FROM collection co
        WHERE co.id = nCollectionID;
       --
       IF nReturn = 0 THEN
         --
         DELETE FROM conference_channel WHERE id = nChannelID;
         --
       --
     END IF;
     
     --
     SET nCount = nCount + 1;
      # main UPDATE
     --
   END LOOP usr_loop;
   --
RETURN nCount;
END