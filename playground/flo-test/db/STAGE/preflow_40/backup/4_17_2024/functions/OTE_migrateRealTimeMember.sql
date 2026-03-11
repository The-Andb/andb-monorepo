CREATE FUNCTION `OTE_migrateRealTimeMember`() RETURNS INT(11)
BEGIN
    DECLARE no_more_rows    boolean;
    DECLARE nCount          INT DEFAULT 0;
    DECLARE nReturn         INT DEFAULT 0;
    DECLARE nID             BIGINT(20);
    DECLARE vEmail          VARCHAR(200);
    DECLARE nRevokeTime     DOUBLE(13,3);
    DECLARE usr_cursor CURSOR FOR
    # Start of: main script;
         SELECT cm.email, rc.id, cm.revoke_time
      FROM conference_member cm
      JOIN realtime_channel rc ON (cm.channel_id = rc.internal_channel_id)
 LEFT JOIN (
           SELECT rcm.id, rcm.email, rc.internal_channel_id
             FROM realtime_channel_member rcm
             JOIN realtime_channel rc ON (rcm.channel_id = rc.id)
            WHERE rc.type = 'CONFERENCE'
           ) rcm ON (cm.email = rcm.email AND cm.channel_id = rcm.internal_channel_id)
      WHERE rcm.id IS NULL
        AND rc.type = 'CONFERENCE'
      ;
       -- LIMIT 10000
    # END of: main script
   DECLARE CONTINUE handler FOR NOT found SET no_more_rows = TRUE;
   --
   OPEN usr_cursor;
   usr_loop: LOOP
     -- start LOOP usr_cursor
     FETCH usr_cursor 
      INTO vEmail, nID, nRevokeTime;
     -- stop LOOP WHEN no_more_rows
     IF (no_more_rows) THEN
       CLOSE usr_cursor;
       LEAVE usr_loop;
     END IF;
     # main UPDATE
     INSERT INTO `realtime_channel_member`
    (`email`, `channel_id`, `revoke_date`, `created_date`, `updated_date`)
    VALUES
    (vEmail, nID, nRevokeTime, unix_timestamp(now(3)), unix_timestamp(now(3)));
     --
     SET nCount = nCount + 1;
      # main UPDATE
     --
   END LOOP usr_loop;
   --
RETURN nCount;
END