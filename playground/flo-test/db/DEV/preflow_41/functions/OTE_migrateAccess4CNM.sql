CREATE FUNCTION `OTE_migrateAccess4CNM`() RETURNS INT
BEGIN
    DECLARE no_more_rows    boolean;
    DECLARE nCount          INT DEFAULT 0;
    DECLARE nReturn         INT DEFAULT 0;
    DECLARE nID             BIGINT(20);
    DECLARE nAccess         TINYINT(1);
    DECLARE usr_cursor CURSOR FOR
    # Start of: main script;
    SELECT cnm.id, csm.access
      FROM collection_notification_member cnm
      JOIN collection_shared_member csm ON (cnm.collection_id = csm.collection_id 
                                            AND csm.access <> cnm.access)
     WHERE cnm.access = 2
       AND csm.access <> 2;
    # END of: main script
   DECLARE CONTINUE handler FOR NOT found SET no_more_rows = TRUE;
   --
   OPEN usr_cursor;
   usr_loop: LOOP
     -- start LOOP usr_cursor
     FETCH usr_cursor INTO nID, nAccess;
     -- stop LOOP WHEN no_more_rows
     IF (no_more_rows) THEN
       CLOSE usr_cursor;
       LEAVE usr_loop;
     END IF;
     # main UPDATE
     UPDATE collection_notification_member cnm
        SET cnm.access = nAccess
      WHERE cnm.id = nID;
     --
     SET nCount = nCount + 1;
      # main UPDATE
     --
   END LOOP usr_loop;
   --
RETURN nCount;
END