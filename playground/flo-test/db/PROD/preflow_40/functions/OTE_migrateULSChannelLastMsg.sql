CREATE FUNCTION `OTE_migrateULSChannelLastMsg`() RETURNS INT
BEGIN
    DECLARE no_more_rows    boolean;
    DECLARE nCount          INT DEFAULT 0;
    DECLARE nReturn         INT DEFAULT 0;
    DECLARE nID             BIGINT(20);
    DECLARE nCreatedDate    DOUBLE(13,3);
    DECLARE usr_cursor CURSOR FOR
    # Start of: main script;
    SELECT uls.id, rm.created_date
      FROM realtime_chat_channel_user_last_seen uls
      JOIN realtime_message rm ON (uls.last_message_uid = rm.uid)
     WHERE uls.last_message_created_date = 0;
    # END of: main script
   DECLARE CONTINUE handler FOR NOT found SET no_more_rows = TRUE;
   --
   OPEN usr_cursor;
   usr_loop: LOOP
     -- start LOOP usr_cursor
     FETCH usr_cursor 
      INTO nID, nCreatedDate;
     -- stop LOOP WHEN no_more_rows
     IF (no_more_rows) THEN
       CLOSE usr_cursor;
       LEAVE usr_loop;
     END IF;
     # main UPDATE
     UPDATE realtime_chat_channel_user_last_seen uls
        SET uls.last_message_created_date = nCreatedDate
      WHERE uls.id = nID
        AND uls.last_message_created_date = 0;
     --
     SET nCount = nCount + 1;
      # main UPDATE
     --
   END LOOP usr_loop;
   --
RETURN nCount;
END