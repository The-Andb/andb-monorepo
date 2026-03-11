CREATE FUNCTION `OTE_RemoveConferenceMember4Viewer`() RETURNS INT
BEGIN
    DECLARE no_more_rows    boolean;
    DECLARE nCount          INT DEFAULT 0;
    DECLARE nReturn         INT DEFAULT 0;
    DECLARE nID             BIGINT(20);
    DECLARE usr_cursor CURSOR FOR
    # Start of: main script;
     SELECT cm.id
       FROM conference_member cm
       JOIN conference_channel cc ON (cc.id = cm.channel_id)
       JOIN collection co ON (co.id = cc.collection_id)
       JOIN collection_shared_member csm ON (csm.shared_email = cm.email AND csm.collection_id = co.id)
      WHERE csm.access = 1
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
     DELETE FROM conference_member
      WHERE id = nID;
     --
     SET nCount = nCount + 1;
      # main UPDATE
     --
   END LOOP usr_loop;
   --
RETURN nCount;
END