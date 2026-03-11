CREATE FUNCTION `OTE_migrateRealTimeUserUsage`() RETURNS INT
BEGIN
    DECLARE no_more_rows    boolean;
    DECLARE nCount          INT DEFAULT 0;
    DECLARE nReturn         INT DEFAULT 0;
    DECLARE nID             BIGINT(20);
    DECLARE vEmail          VARCHAR(100);
    DECLARE usr_cursor CURSOR FOR
    # Start of: main script;
     SELECT u.email
       FROM user u
       LEFT JOIN realtime_user_usage ruu ON u.email = ruu.email
       WHERE ruu.id IS NULL;
       -- LIMIT 10000
    # END of: main script
   DECLARE CONTINUE handler FOR NOT found SET no_more_rows = TRUE;
   --
   OPEN usr_cursor;
   usr_loop: LOOP
     -- start LOOP usr_cursor
     FETCH usr_cursor 
      INTO vEmail;
     -- stop LOOP WHEN no_more_rows
     IF (no_more_rows) THEN
       CLOSE usr_cursor;
       LEAVE usr_loop;
     END IF;
     # main UPDATE
       INSERT IGNORE INTO `realtime_user_usage`
        (`email`, `message_size_usage`, `message_count`, `channel_count`, `attachment_size_usage`, `attachment_count`, `created_date`, `updated_date`)
       VALUES
        (vEmail, 0, 0, 0, 0, 0, unix_timestamp(now(3)), unix_timestamp(now(3)));
     --
     SET nCount = nCount + 1;
      # main UPDATE
     --
   END LOOP usr_loop;
   --
RETURN nCount;
END