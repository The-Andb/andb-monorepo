CREATE FUNCTION `OTE_migrateRealTimeCollectionViewer`() RETURNS INT(11)
BEGIN
    DECLARE no_more_rows    boolean;
    DECLARE nCount          INT DEFAULT 0;
    DECLARE nReturn         INT DEFAULT 0;
    DECLARE nID             BIGINT(20);
    DECLARE usr_cursor CURSOR FOR
    # Start of: main script;
    SELECT rcm.id
      FROM collection_shared_member csm
      JOIN realtime_channel rc ON (csm.collection_id = rc.internal_channel_id)
      JOIN realtime_channel_member rcm ON (csm.shared_email = rcm.email AND rc.id = rcm.channel_id)
     WHERE rc.type = 'COLLECTION'
       AND rcm.role = 2
       AND csm.access = 1
      ;
    # END of: main script
   DECLARE CONTINUE handler FOR NOT found SET no_more_rows = TRUE;
   --
   OPEN usr_cursor;
   usr_loop: LOOP
     -- start LOOP usr_cursor
     FETCH usr_cursor 
      INTO nID;
     -- stop LOOP WHEN no_more_rows
     IF (no_more_rows) THEN
       CLOSE usr_cursor;
       LEAVE usr_loop;
     END IF;
     # main UPDATE
     UPDATE realtime_channel_member rcm
        SET rcm.role  = 1
      WHERE rcm.id    = nID
        AND rcm.role  = 2;
     --
     SET nCount = nCount + 1;
      # main UPDATE
     --
   END LOOP usr_loop;
   --
RETURN nCount;
END