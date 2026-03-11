CREATE FUNCTION `c2023_createNotificationV2`(pnUserId             BIGINT(20)
                                                          ,pvUsername            VARCHAR(255)
                                                          ,pnCollectionId        BIGINT(20)
                                                          ,pnCommentId           INT(11)
                                                          ,pvObjectUid           VARBINARY(1000)
                                                          ,pvObjectType          VARBINARY(50)
                                                          ,pnAction              INT(11)
                                                          ,pnActionTime          DOUBLE(13,3)
                                                          ,pvAssignee            TEXT
                                                          ,pvContent             VARCHAR(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
                                                          ,pnUpdatedDate         DOUBLE(13,3)
                                                          ) RETURNS BIGINT
BEGIN
  --
  DECLARE nReturn       INT DEFAULT 0;
  DECLARE nNotiID       BIGINT(20) DEFAULT 0;
  DECLARE nLastAPI      INT DEFAULT 0;
  DECLARE vContent      VARCHAR(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT pvContent;
  DECLARE nHasMention   TINYINT(1) DEFAULT 0;
  --
  IF ifnull(vContent, '') = '' THEN
    --
    SET vContent = c2024_getObjectSummary(pvObjectUid, pvObjectType);
    --
  END IF;
  --
  INSERT INTO collection_notification
    (user_id, email, collection_id, comment_id, object_uid, object_type, 
    `action`, action_time, assignees, content, created_date, updated_date)
  VALUES
    (pnUserId, pvUsername, pnCollectionId, CASE WHEN pnAction IN (6, 61, 62) THEN pnCommentId ELSE 0 END, pvObjectUid, pvObjectType
    ,pnAction, pnActionTime, CASE WHEN pnAction IN (17, 18) THEN ifnull(pvAssignee, '') ELSE '' END, ifnull(vContent, ''), pnUpdatedDate, pnUpdatedDate);
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
  RETURN nNotiID;
  --
END