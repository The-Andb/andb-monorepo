CREATE FUNCTION `OTE_migrateRealTimeMemberLastSeenDisable`() RETURNS INT
BEGIN
    DECLARE no_more_rows    boolean;
    DECLARE nCount          INT DEFAULT 0;
    DECLARE nReturn         INT DEFAULT 0;
    DECLARE nID             BIGINT(20);
    DECLARE usr_cursor CURSOR FOR
    # Start of: main script;
    SELECT uls.id
      FROM realtime_channel_member rcm
  JOIN realtime_chat_channel_user_last_seen uls ON (rcm.channel_name = uls.channel_name AND rcm.email = uls.email)
  JOIN realtime_channel rc ON (rc.id = rcm.channel_id)
   JOIN conference_member cm ON (rcm.email = cm.email
                                 AND rc.internal_channel_id = cm.channel_id 
                                 AND rc.type = 'CONFERENCE')
     WHERE cm.revoke_time > 0
     AND uls.disabled = 0
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
     UPDATE realtime_chat_channel_user_last_seen uls
        SET uls.disabled = 1
        WHERE uls.id = nID;
     --
     SET nCount = nCount + 1;
      # main UPDATE
     --
   END LOOP usr_loop;
   --
RETURN nCount;
END