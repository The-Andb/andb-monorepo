CREATE FUNCTION `OTE_migrateRealTimeMemberChannelName`() RETURNS INT
BEGIN
    DECLARE no_more_rows    boolean;
    DECLARE nCount          INT DEFAULT 0;
    DECLARE nReturn         INT DEFAULT 0;
    DECLARE nID             BIGINT(20);
    DECLARE vCName          VARCHAR(100);
    DECLARE vEmail          VARCHAR(200);
    DECLARE nRevokeTime     DOUBLE(13,3);
    DECLARE usr_cursor CURSOR FOR
    # Start of: main script;
    SELECT rc.name, rcm.id
      FROM realtime_channel rc
      JOIN realtime_channel_member rcm ON (rc.id = rcm.channel_id)
     WHERE rcm.channel_name IS NULL
    -- LIMIT 100000
       ;
    # END of: main script
   DECLARE CONTINUE handler FOR NOT found SET no_more_rows = TRUE;
   --
   OPEN usr_cursor;
   usr_loop: LOOP
     -- start LOOP usr_cursor
     FETCH usr_cursor 
      INTO vCName, nID;
     -- stop LOOP WHEN no_more_rows
     IF (no_more_rows) THEN
       CLOSE usr_cursor;
       LEAVE usr_loop;
     END IF;
     # main UPDATE
     UPDATE realtime_channel_member rcm
        SET rcm.channel_name = vCName
      WHERE rcm.id = nID;
     --
     SET nCount = nCount + 1;
      # main UPDATE
     --
   END LOOP usr_loop;
   --
RETURN nCount;
END