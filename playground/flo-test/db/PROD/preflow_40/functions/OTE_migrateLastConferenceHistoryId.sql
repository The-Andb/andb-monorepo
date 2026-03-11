CREATE FUNCTION `OTE_migrateLastConferenceHistoryId`() RETURNS INT
BEGIN
    DECLARE no_more_rows    boolean;
    DECLARE nCount          INT DEFAULT 0;
    DECLARE nReturn         INT DEFAULT 0;
    DECLARE nMemberID       BIGINT(20);
    DECLARE nUserId         BIGINT(20);
    DECLARE nHistoryId      BIGINT(20);
    DECLARE usr_cursor CURSOR FOR
    # Start of: main script;
    SELECT cm.id, cm.user_id
      FROM conference_member cm
      WHERE cm.revoke_time = 0;
    # END of: main script
   DECLARE CONTINUE handler FOR NOT found SET no_more_rows = TRUE;
   --
   OPEN usr_cursor;
   usr_loop: LOOP
     -- start LOOP usr_cursor
     FETCH usr_cursor 
      INTO nMemberID, nUserId;
     -- stop LOOP WHEN no_more_rows
     IF (no_more_rows) THEN
       CLOSE usr_cursor;
       LEAVE usr_loop;
     END IF;
     --
     SELECT ifnull(max(ch1.id), 0)
      INTO nHistoryId
      FROM conference_history ch1
     WHERE ch1.user_id = nUserId
       AND ch1.member_id = nMemberID
     ORDER BY ch1.start_time DESC
     ;
     --
     IF nHistoryId > 0 THEN
       --
        UPDATE conference_member cm
            SET cm.last_history_id = nHistoryId
          WHERE cm.id = nMemberID
            AND cm.user_id = nUserId
            AND cm.revoke_time  = 0;
       --
     END IF;
     SET nCount = nCount + 1;
      # main UPDATE
     --
   END LOOP usr_loop;
   --
RETURN nCount;
END