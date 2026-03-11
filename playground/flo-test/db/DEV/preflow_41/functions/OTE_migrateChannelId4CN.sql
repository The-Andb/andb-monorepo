CREATE FUNCTION `OTE_migrateChannelId4CN`() RETURNS INT
BEGIN
    DECLARE no_more_rows    boolean;
    DECLARE nCount          INT DEFAULT 0;
    DECLARE nReturn         INT DEFAULT 0;
    DECLARE nID             BIGINT(20);
    DECLARE nCID            INT;
    DECLARE usr_cursor CURSOR FOR
    # Start of: main script;
    SELECT cn.id, co.channel_id
      FROM collection_notification cn
      JOIN collection co ON (cn.collection_id = co.id)
     WHERE cn.channel_id = 0
       AND co.channel_id IS NOT NULL;
    # END of: main script
   DECLARE CONTINUE handler FOR NOT found SET no_more_rows = TRUE;
   --
   OPEN usr_cursor;
   usr_loop: LOOP
     -- start LOOP usr_cursor
     FETCH usr_cursor INTO nID, nCID;
     -- stop LOOP WHEN no_more_rows
     IF (no_more_rows) THEN
       CLOSE usr_cursor;
       LEAVE usr_loop;
     END IF;
     # main UPDATE
     UPDATE collection_notification cn
        SET cn.channel_id = nCID
      WHERE cn.id = nID;
     --
     SET nCount = nCount + 1;
      # main UPDATE
     --
   END LOOP usr_loop;
   --
RETURN nCount;
END