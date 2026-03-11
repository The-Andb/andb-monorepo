CREATE FUNCTION `r2024_cleanupRealtimeChannel`(pnChannelID BIGINT(20)) RETURNS INT
BEGIN
    DECLARE no_more_rows        boolean;
    DECLARE nCount              INT DEFAULT 0;
    DECLARE nReturn             BIGINT(20) DEFAULT 0;
    DECLARE nRCMID               INT DEFAULT 0;
    DECLARE usr_cursor CURSOR FOR
    # Start of: main script;
  SELECT rcm.id
    FROM realtime_channel_member rcm
    WHERE rcm.channel_id = pnChannelID
      ;
    # END of: main script
   DECLARE CONTINUE handler FOR NOT found SET no_more_rows = TRUE;
   --
   OPEN usr_cursor;
   usr_loop: LOOP
     -- start LOOP usr_cursor
     FETCH usr_cursor 
      INTO nRCMID;
     -- stop LOOP WHEN no_more_rows
     IF (no_more_rows) THEN
       CLOSE usr_cursor;
       LEAVE usr_loop;
     END IF;
     # main UPDATE
     -- DELETE realtime_channel_member
     DELETE FROM realtime_channel_member WHERE id = nRCMID;
     --
     SET nCount = nCount + 1;
      # main UPDATE
     --
   END LOOP usr_loop;
   --
   DELETE FROM realtime_channel WHERE id = pnChannelID;
   IF ROW_COUNT() > 0 THEN
       SET nCount = nCount + 1;
    END IF;
   --
  RETURN nCount;
  --
END