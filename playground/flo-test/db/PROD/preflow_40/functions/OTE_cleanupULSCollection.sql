CREATE FUNCTION `OTE_cleanupULSCollection`() RETURNS INT
BEGIN
    DECLARE no_more_rows        boolean;
    DECLARE nCount              INT DEFAULT 0;
    DECLARE nULSID              INT DEFAULT 0;
    DECLARE nCollectionID       BIGINT(20) DEFAULT 0;
    DECLARE nExisted            TINYINT(1) DEFAULT 0;
    DECLARE vEmail              VARCHAR(100);
    DECLARE usr_cursor CURSOR FOR
    # Start of: main script;
    SELECT uls.id, rc.internal_channel_id, uls.email
      FROM realtime_channel_member rcm
      JOIN realtime_chat_channel_user_last_seen uls ON (rcm.channel_name = uls.channel_name AND rcm.email = uls.email)
      JOIN realtime_channel rc ON (rc.id = rcm.channel_id)
 LEFT JOIN collection_shared_member csm ON (rcm.email = csm.shared_email AND rc.internal_channel_id = csm.collection_id)
     WHERE uls.disabled = 0
       AND rc.type = 'COLLECTION'
       AND csm.id IS NULL
     ;
    # END of: main script
   DECLARE CONTINUE handler FOR NOT found SET no_more_rows = TRUE;
   --
   OPEN usr_cursor;
   usr_loop: LOOP
     -- start LOOP usr_cursor
     FETCH usr_cursor 
      INTO nULSID, nCollectionID, vEmail;
     -- stop LOOP WHEN no_more_rows
     IF (no_more_rows) THEN
       CLOSE usr_cursor;
       LEAVE usr_loop;
     END IF;
     # main UPDATE
     SELECT ifnull(max(csm.id), 0) > 0
       INTO nExisted
       FROM collection_shared_member csm
      WHERE csm.collection_id = nCollectionID
        AND csm.shared_email      = vEmail;
     --
     DELETE FROM realtime_chat_channel_user_last_seen 
        WHERE id = nULSID;
     --
     SET nCount = nCount + 1;
      # main UPDATE
     --
  END LOOP usr_loop;
  --
  RETURN nCount;
  --
END