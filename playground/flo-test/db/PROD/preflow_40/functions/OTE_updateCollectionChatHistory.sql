CREATE FUNCTION `OTE_updateCollectionChatHistory`(pvEmail VARCHAR(100)) RETURNS INT
BEGIN
    DECLARE no_more_rows    boolean;
    DECLARE nCount          INT DEFAULT 0;
    DECLARE nReturn         INT DEFAULT 0;
    DECLARE nID             BIGINT(20);
    DECLARE nChannelID      BIGINT(20);
    DECLARE nEnable         TINYINT(1);
    DECLARE nViewHistory    TINYINT(1);
    DECLARE usr_cursor CURSOR FOR
    # Start of: main script;
    SELECT cm.id, cm.channel_id, cc.enable_chat_history, cm.view_chat_history
    FROM conference_channel cc
    JOIN conference_member cm ON cc.id = cm.channel_id
    JOIN user u ON cm.user_id = u.id
    WHERE (pvEmail IS NULL OR u.email = pvEmail)
    AND cc.collection_id > 0 
    AND (cc.enable_chat_history = 0 OR cm.view_chat_history = 0)
    ;
    # END of: main script
   DECLARE CONTINUE handler FOR NOT found SET no_more_rows = TRUE;
   --
   OPEN usr_cursor;
   usr_loop: LOOP
     -- start LOOP usr_cursor
     FETCH usr_cursor 
      INTO nID, nChannelID, nEnable, nViewHistory;
     -- stop LOOP WHEN no_more_rows
     IF (no_more_rows) THEN
       CLOSE usr_cursor;
       LEAVE usr_loop;
     END IF;
     # main UPDATE
     IF nEnable = 0 THEN
       --
       UPDATE conference_channel cc
          SET cc.enable_chat_history = 1
        WHERE cc.id = nChannelID
          AND cc.enable_chat_history = 0;
       --
     END IF;
     --
     IF nViewHistory = 0 THEN
       --
       UPDATE conference_member cm
          SET cm.view_chat_history = 1
        WHERE cm.id = nID
          AND cm.view_chat_history = 0;
       --
     END IF;
     --
     SET nCount = nCount + 1;
      # main UPDATE
     --
   END LOOP usr_loop;
   --
RETURN nCount;
END