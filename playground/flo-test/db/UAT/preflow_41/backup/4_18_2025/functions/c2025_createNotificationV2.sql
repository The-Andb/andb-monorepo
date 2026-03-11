CREATE FUNCTION `c2025_createNotificationV2`(pnUserId             BIGINT(20)
                                                          ,pvUsername            VARCHAR(255)
                                                          ,pnCollectionId        BIGINT(20)
                                                          ,pnCommentId           INT(11)
                                                          ,pvObjectUid           VARBINARY(1000)
                                                          ,pvObjectType          VARBINARY(50)
                                                          ,pnAction              INT(11)
                                                          ,pnActionTime          DOUBLE(13,3)
                                                          ,pvAssignee            TEXT
                                                          ,pvContent             VARCHAR(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
                                                          ,pnKanbanID            BIGINT(20)
                                                          ,pnUpdatedDate         DOUBLE(13,3)
                                                          ) RETURNS TEXT CHARSET latin1
BEGIN
  --
  DECLARE nReturn       INT DEFAULT 0;
  DECLARE nNotiID       BIGINT(20) DEFAULT 0;
  DECLARE nLastAPI      INT DEFAULT 0;
  DECLARE vContent      VARCHAR(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
  DECLARE nHasMention   TINYINT(1) DEFAULT 0;
  DECLARE nCategory     TINYINT(1) DEFAULT 0;
  --
  SET vContent = ifnull(pvContent, '');
  --
  IF vContent = '' THEN
    --
   SET vContent = o2024_getObjectTitle(pvObjectUid, pvObjectType); 
    --
  END IF;
  -- GET category
  IF pvObjectType = 'VTODO' THEN
  SELECT ifnull(ct.category, 0)
    INTO nCategory
    FROM cal_todo ct
   WHERE ct.uid = pvObjectUid;
  END IF;
  --
  INSERT INTO collection_notification
    (user_id, email, collection_id, comment_id, object_uid, object_type, 
    `action`, action_time, assignees, content, kanban_id, created_date, updated_date, category)
  VALUES
    (pnUserId, pvUsername, pnCollectionId, CASE WHEN pnAction IN (6, 61, 62) THEN pnCommentId ELSE 0 END, pvObjectUid, pvObjectType
    ,pnAction, pnActionTime, CASE WHEN pnAction IN (17, 18) THEN ifnull(pvAssignee, '') ELSE '' END, ifnull(vContent, ''), pnKanbanID, pnUpdatedDate, pnUpdatedDate, nCategory);
  --
  SET nNotiID = LAST_INSERT_ID();
  --
  SET nReturn = n2024_afterCreateNotification4SharedCollection(nNotiID,
     pnCollectionId, pvObjectType, pnAction, pvUsername, pvAssignee, pnActionTime, pnUpdatedDate, pnUpdatedDate);
  
  -- always USE post history FOR this CASE
  IF pnAction = 6 THEN
    --
    SET nReturn = n2024_considerMentionInNotification(nNotiID, pnCommentId, pnActionTime, pnUpdatedDate);
    --
  END IF;
  --
  RETURN JSON_OBJECT('id', nNotiID, 'category', nCategory);
  --
END