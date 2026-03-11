CREATE FUNCTION `OTE_migrateObjectType4Notification`() RETURNS INT
BEGIN
    DECLARE no_more_rows      boolean;
    DECLARE nCount            INT DEFAULT 0;
    DECLARE nReturn           INT DEFAULT 0;
    DECLARE nCnID             BIGINT(20);
    DECLARE vObjectType       VARBINARY(50);
    DECLARE vObjectUid        VARBINARY(1000);
    DECLARE vOldObjectType    VARBINARY(50);
    DECLARE usr_cursor CURSOR FOR
    # Start of: main script;
    SELECT ca.object_type, ca.object_uid, cn.object_type, cn.id
      FROM collection_notification cn
      JOIN collection_comment cc ON cn.comment_id = cc.id
      JOIN collection_activity ca ON ca.id = cc.collection_activity_id
     WHERE cn.object_type = 'COMMENT'
     ;

    # END of: main script
   DECLARE CONTINUE handler FOR NOT found SET no_more_rows = TRUE;
   --
   OPEN usr_cursor;
   usr_loop: LOOP
     -- start LOOP usr_cursor
     FETCH usr_cursor 
      INTO vObjectType, vObjectUid, vOldObjectType, nCnID;
     -- stop LOOP WHEN no_more_rows
     IF (no_more_rows) THEN
       CLOSE usr_cursor;
       LEAVE usr_loop;
     END IF;
     # main UPDATE
     UPDATE collection_notification cn
        SET cn.object_type = vObjectType
           ,cn.object_uid = vObjectUid
      WHERE cn.id = nCnID
        AND cn.object_type = vOldObjectType;
     --
     SET nCount = nCount + 1;
      # main UPDATE
     --
   END LOOP usr_loop;
   --
RETURN nCount;
END