CREATE FUNCTION `r2024_migrateConferenceRealtimeChannel`() RETURNS INT
BEGIN
    DECLARE no_more_rows    boolean;
    DECLARE nCount          INT DEFAULT 0;
    DECLARE nReturn         INT DEFAULT 0;
    DECLARE nID             BIGINT(20);
    DECLARE nRCID           BIGINT(20);
    DECLARE vTitle          VARCHAR(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    DECLARE usr_cursor CURSOR FOR
    # Start of: main script;
     SELECT cc.id, cc.title
       FROM conference_channel cc
  LEFT JOIN realtime_channel rc ON (cc.id = rc.internal_channel_id AND rc.type = 'CONFERENCE')
      WHERE rc.id IS NULL
         OR cc.realtime_channel = ''
       LIMIT 10000;
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
     SELECT ifnull(max(rc.id), 0)
      INTO nRCID
      FROM realtime_channel rc
     WHERE rc.internal_channel_id = nID
       AND rc.type = 'CONFERENCE';
     --
     IF nRCID = 0 THEN 
       --
       INSERT INTO `realtime_channel`
         (`name`,`title`,`type`,`internal_channel_id`,`created_date`,`updated_date`)
       VALUES
         (concat('CONFERENCE_', nID), vTitle,'CONFERENCE',nID,unix_timestamp(now(3)), unix_timestamp(now(3)))
         ON DUPLICATE KEY UPDATE updated_date = VALUES(updated_date),
                    internal_channel_id = VALUES(internal_channel_id);
       --
     END IF;
     --
     UPDATE conference_channel cc
        SET cc.realtime_channel = concat('CONFERENCE_', nID)
      WHERE cc.id = nID;
     --
     SET nCount = nCount + 1;
      # main UPDATE
     --
   END LOOP usr_loop;
   --
RETURN nCount;
END