CREATE FUNCTION `OTE_updateFieldRealtimeChannelTitle`() RETURNS INT(11)
BEGIN
    DECLARE no_more_rows    boolean;
    DECLARE nCount          INT DEFAULT 0;
    DECLARE nReturn         INT DEFAULT 0;
    DECLARE nID             BIGINT(20);
    DECLARE vTitle          VARCHAR(200)  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    DECLARE usr_cursor CURSOR FOR
    # Start of: main script;
     SELECT rc.id, cc.title
       FROM realtime_channel rc
       JOIN conference_channel cc ON (cc.id = rc.internal_channel_id)
       WHERE cc.title <> rc.title
      ;
       -- LIMIT 10000
    # END of: main script
   DECLARE CONTINUE handler FOR NOT found SET no_more_rows = TRUE;
   --
   OPEN usr_cursor;
   usr_loop: LOOP
     -- start LOOP usr_cursor
     FETCH usr_cursor 
      INTO nID, vTitle;
     -- stop LOOP WHEN no_more_rows
     IF (no_more_rows) THEN
       CLOSE usr_cursor;
       LEAVE usr_loop;
     END IF;
     # main UPDATE
     UPDATE realtime_channel rc
        SET rc.title = vTitle
      WHERE rc.id = nID;
     --
     SET nCount = nCount + 1;
      # main UPDATE
     --
   END LOOP usr_loop;
   --
RETURN nCount;
END