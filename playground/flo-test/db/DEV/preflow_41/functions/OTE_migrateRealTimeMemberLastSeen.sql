CREATE FUNCTION `OTE_migrateRealTimeMemberLastSeen`() RETURNS INT
BEGIN
    DECLARE no_more_rows    boolean;
    DECLARE nCount          INT DEFAULT 0;
    DECLARE nReturn         INT DEFAULT 0;
    DECLARE nID             BIGINT(20);
    DECLARE vCName          VARCHAR(100);
    DECLARE nCID            INT;
    DECLARE vEmail          VARCHAR(200);
    DECLARE nRevokeTime     DOUBLE(13,3);
    DECLARE usr_cursor CURSOR FOR
    # Start of: main script;
    SELECT cm.email, cm.channel_id, rc.`name`
      FROM realtime_channel_member cm
      JOIN realtime_channel rc ON (cm.channel_id = rc.id)
 LEFT JOIN realtime_chat_channel_user_last_seen uls ON (rc.`name` = uls.channel_name
                                                            AND cm.email = uls.email)
     WHERE uls.id IS NULL
       AND rc.`name` IS NOT NULL
       -- AND cm.channel_name IS NULL
      LIMIT 500000
         ;
    # END of: main script
   DECLARE CONTINUE handler FOR NOT found SET no_more_rows = TRUE;
   --
   OPEN usr_cursor;
   usr_loop: LOOP
     -- start LOOP usr_cursor
     FETCH usr_cursor 
      INTO vEmail, nCID, vCName;
     -- stop LOOP WHEN no_more_rows
     IF (no_more_rows) THEN
       CLOSE usr_cursor;
       LEAVE usr_loop;
     END IF;
     # main UPDATE
     INSERT INTO `realtime_chat_channel_user_last_seen`
            (`email`, `channel_name`, `channel_id`, `last_message_uid`, `channel_last_message_uid`, `unread`, `last_seen`, `created_date`, `updated_date`)
     VALUES (vEmail, vCName, nCID, '', NULL, 0, 0, unix_timestamp(now(3)), unix_timestamp(now(3)));
     --
     SET nCount = nCount + 1;
      # main UPDATE
     --
   END LOOP usr_loop;
   --
RETURN nCount;
END