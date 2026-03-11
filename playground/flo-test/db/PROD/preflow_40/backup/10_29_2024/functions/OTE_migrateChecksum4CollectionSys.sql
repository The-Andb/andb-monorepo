CREATE FUNCTION `OTE_migrateChecksum4CollectionSys`() RETURNS INT(11)
BEGIN
    DECLARE no_more_rows    boolean;
    DECLARE nCount          INT DEFAULT 0;
    DECLARE nReturn         INT DEFAULT 0;
    DECLARE vName           VARCHAR(100);
    DECLARE vChecksum       VARCHAR(100);
    DECLARE nUserId         BIGINT(20);
    DECLARE nID             BIGINT(20);
    DECLARE usr_cursor CURSOR FOR
    # Start of: main script;
    SELECT cs.name, cs.user_id, cs.id
      FROM collection_system cs
     WHERE cs.checksum IS NULL
       AND cs.user_id = 57461
     ;
    # END of: main script
   DECLARE CONTINUE handler FOR NOT found SET no_more_rows = TRUE;
   --
   OPEN usr_cursor;
   usr_loop: LOOP
     -- start LOOP usr_cursor
     FETCH usr_cursor 
      INTO vName, nUserId, nID;
     -- stop LOOP WHEN no_more_rows
     IF (no_more_rows) THEN
       CLOSE usr_cursor;
       LEAVE usr_loop;
     END IF;
     --
     # main UPDATE
     UPDATE collection_system cs
        SET cs.checksum = MD5(concat(vName, nUserId))
      WHERE cs.id = nID
       AND cs.checksum IS NULL;
     --
     SET nCount = nCount + 1;
     # main UPDATE
     --
   END LOOP usr_loop;
   --
RETURN nCount;
END