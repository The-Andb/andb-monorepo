CREATE FUNCTION `OTE_fixRealtimeChannelConferenceName`() RETURNS INT
BEGIN
    DECLARE no_more_rows    boolean;
    DECLARE nCount          INT DEFAULT 0;
    DECLARE nReturn         INT DEFAULT 0;
    DECLARE nID             BIGINT(20);
    DECLARE usr_cursor CURSOR FOR
    # Start of: main script;
     SELECT cc.id
     FROM conference_channel cc
     WHERE cc.realtime_channel LIKE 'COLLECTION_%';
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
     UPDATE conference_channel cc
        SET cc.realtime_channel = concat('CONFERENCE_', nID)
      WHERE cc.id = nID;
     --
     SET nCount = nCount + 1;
      # main UPDATE
     --
   END LOOP usr_loop;
   
   -- SET nReturn = OTE_updateFieldRealtimeChannel();
   --
RETURN nCount;
END