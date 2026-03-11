CREATE FUNCTION `OTE_updateFieldRealtimeChannel`() RETURNS INT
BEGIN
    DECLARE no_more_rows    boolean;
    DECLARE nCount          INT DEFAULT 0;
    DECLARE nReturn         INT DEFAULT 0;
    DECLARE nID             BIGINT(20);
    DECLARE vName           VARCHAR(200);
    DECLARE usr_cursor CURSOR FOR
    # Start of: main script;
     SELECT rc.internal_channel_id, rc.name
       FROM realtime_channel rc
       JOIN conference_channel cc ON (cc.id = rc.internal_channel_id)
       WHERE cc.realtime_channel = ''
      ;
       -- LIMIT 10000
    # END of: main script
   DECLARE CONTINUE handler FOR NOT found SET no_more_rows = TRUE;
   --
   OPEN usr_cursor;
   usr_loop: LOOP
     -- start LOOP usr_cursor
     FETCH usr_cursor 
      INTO nID, vName;
     -- stop LOOP WHEN no_more_rows
     IF (no_more_rows) THEN
       CLOSE usr_cursor;
       LEAVE usr_loop;
     END IF;
     # main UPDATE
     UPDATE conference_channel cc
        SET cc.realtime_channel = vName
      WHERE cc.id = nID;
     --
     SET nCount = nCount + 1;
      # main UPDATE
     --
   END LOOP usr_loop;
   --
RETURN nCount;
END