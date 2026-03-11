CREATE FUNCTION `OTE_migrateRealTimeCollection`() RETURNS INT(11)
BEGIN
    DECLARE no_more_rows    boolean;
    DECLARE nCount          INT DEFAULT 0;
    DECLARE nReturn         INT DEFAULT 0;
    DECLARE nID             BIGINT(20);
    DECLARE vTitle          VARCHAR(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    DECLARE usr_cursor CURSOR FOR
    # Start of: main script;
     SELECT co.id, co.name
       FROM collection co
  LEFT JOIN realtime_channel rc ON (co.id = rc.internal_channel_id AND rc.type = 'COLLECTION')
      WHERE rc.id IS NULL
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
     INSERT INTO `realtime_channel`
       (`name`,`title`,`type`,`internal_channel_id`,`created_date`,`updated_date`)
     VALUES
       (concat('COLLECTION_', nID), vTitle,'COLLECTION',nID,unix_timestamp(now(3)), unix_timestamp(now(3)))
        ON DUPLICATE KEY UPDATE updated_date = VALUES(updated_date),
                    internal_channel_id = VALUES(internal_channel_id),
                              `type`=VALUES(`type`);
     --
     SET nCount = nCount + 1;
      # main UPDATE
     --
   END LOOP usr_loop;
   
   SET nReturn = OTE_updateFieldRealtimeChannelCollection();
   --
RETURN nCount;
END