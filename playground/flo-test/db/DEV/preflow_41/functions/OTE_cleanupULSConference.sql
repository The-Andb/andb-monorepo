CREATE FUNCTION `OTE_cleanupULSConference`() RETURNS INT
BEGIN
    DECLARE no_more_rows        boolean;
    DECLARE nCount              INT DEFAULT 0;
    DECLARE nULSID              INT DEFAULT 0;
    DECLARE nChannelID          BIGINT(20) DEFAULT 0;
    DECLARE nExisted            TINYINT(1) DEFAULT 0;
    DECLARE vEmail              VARCHAR(100);
    DECLARE usr_cursor CURSOR FOR
    # Start of: main script;
    SELECT uls.id, rc.internal_channel_id, uls.email
      FROM realtime_chat_channel_user_last_seen uls
      JOIN realtime_channel rc ON (rc.id = uls.channel_id)
 LEFT JOIN conference_member cm ON (uls.email = cm.email AND rc.internal_channel_id = cm.channel_id)
     WHERE uls.disabled = 0
       AND rc.type = 'CONFERENCE'
       AND cm.id IS NULL
      ;
    # END of: main script
   DECLARE CONTINUE handler FOR NOT found SET no_more_rows = TRUE;
   --
   OPEN usr_cursor;
   usr_loop: LOOP
     -- start LOOP usr_cursor
     FETCH usr_cursor 
      INTO nULSID, nChannelID, vEmail;
     -- stop LOOP WHEN no_more_rows
     IF (no_more_rows) THEN
       CLOSE usr_cursor;
       LEAVE usr_loop;
     END IF;
     # main UPDATE
     --
     DELETE FROM realtime_chat_channel_user_last_seen 
     WHERE id = nULSID;
     --
     SET nCount = nCount + 1;
      # main UPDATE
     --
   END LOOP usr_loop;
   --
  RETURN nCount;
  --
END