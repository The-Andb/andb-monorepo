CREATE FUNCTION `OTE_patchShareTitle4Conference`() RETURNS INT
BEGIN
    DECLARE no_more_rows    boolean;
    DECLARE nCount          INT DEFAULT 0;
    DECLARE nReturn         INT DEFAULT 0;
    DECLARE nID             BIGINT(20);
    DECLARE nChannelID      BIGINT(20);
    DECLARE nUserID         BIGINT(20);
    DECLARE vTitle          VARCHAR(255);
    DECLARE nUpdatedDate    DOUBLE(13,3);
    DECLARE usr_cursor CURSOR FOR
    # Start of: main script;
    SELECT cm.id, cc.id, cm.user_id, co.name
      FROM conference_channel cc
      JOIN collection co ON (cc.collection_id = co.id)
 LEFT JOIN conference_member cm ON (cm.channel_id = cc.id AND cm.user_id = cc.user_id)
     WHERE co.pt_project_id <> 0
       AND co.name <> cc.title
       AND co.type = 3
       -- AND cm.id = 2757612
     LIMIT 100;
    # END of: main script
   DECLARE CONTINUE handler FOR NOT found SET no_more_rows = TRUE;
   --
   OPEN usr_cursor;
   usr_loop: LOOP
     -- start LOOP usr_cursor
     FETCH usr_cursor 
      INTO nID, nChannelID, nUserID, vTitle;
     -- stop LOOP WHEN no_more_rows
     IF (no_more_rows) THEN
       CLOSE usr_cursor;
       LEAVE usr_loop;
     END IF;
     # main UPDATE
     SET nUpdatedDate = UNIX_TIMESTAMP(NOW(3));
     -- send channel
     UPDATE conference_channel cc
        SET cc.title = vTitle
           ,cc.updated_date = nUpdatedDate
      WHERE cc.id = nChannelID;
     --
     SET nReturn = c2023_sendLastModifyConference('conference_member', nChannelID, nUpdatedDate);
     -- send owner
     UPDATE conference_member cm
        SET cm.title = vTitle
           ,cm.updated_date = nUpdatedDate
      WHERE cm.id = nID;
     --
     SET nReturn = m2023_insertAPILastModify('conferencing', nUserId, nUpdatedDate);
     SET nCount = nCount + 1;
      # main UPDATE
     --
   END LOOP usr_loop;
   --
RETURN nCount;
END