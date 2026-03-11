CREATE FUNCTION `c2024_createNotificationV2`(pnUserId             BIGINT(20)
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
                                                          ,pnChannelId           BIGINT(20)
                                                          ,pvEmojiUnicode        VARCHAR(100)
                                                          ) RETURNS BIGINT
BEGIN
  --
  DECLARE nReturn       INT DEFAULT 0;
  DECLARE nNotiID       BIGINT(20) DEFAULT 0;
  DECLARE nLastAPI      INT DEFAULT 0;
  DECLARE vContent      VARCHAR(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
  DECLARE nHasMention   TINYINT(1) DEFAULT 0;
  DECLARE nCollectionId BIGINT(20) DEFAULT 0;
  DECLARE nUserId       BIGINT(20) DEFAULT ifnull(pnUserId, 0);
  DECLARE vUsername     VARCHAR(255) DEFAULT ifnull(pvUsername, '');
  --
  SET vContent = ifnull(pvContent, '');
  IF vContent = '' THEN
    --
    CASE ifnull(pvObjectType, '')
      --
      WHEN 'URL' THEN
        --
        SELECT ifnull(u.title, '') 
          INTO vContent 
          FROM url u
         WHERE u.uid = pvObjectUid
         LIMIT 1;
        --
      WHEN 'VTODO' THEN
        --
        SELECT ifnull(ct.summary, '')
          INTO vContent 
          FROM cal_todo ct 
         WHERE ct.uid = pvObjectUid
         LIMIT 1;
        --
      WHEN 'VEVENT' THEN
        --
        SELECT ifnull(ce.summary, '')
          INTO vContent 
          FROM cal_event ce 
         WHERE ce.uid = pvObjectUid 
         LIMIT 1;
        --
      WHEN 'VJOURNAL' THEN
        --
        SELECT ifnull(cn.summary, '')
          INTO vContent
          FROM cal_note cn
         WHERE cn.uid = pvObjectUid
         LIMIT 1;
      ELSE
        --
        SET vContent = ''; 
        --
    END CASE;
    --
  END IF;
 
 -- Only CREATE for owner comment
  IF ifnull(pvObjectType, '') = 'COMMENT' AND ifnull(pnCommentId, 0) > 0 THEN
    SELECT cc.user_id, cc.email INTO nUserId, vUsername
    FROM collection_comment cc
    WHERE cc.id = pnCommentId;
  END IF;
 
 -- Only CREATE for owner chat
  IF ifnull(pvObjectType, '') = 'CHAT' AND ifnull(pvObjectUid, '') <> '' THEN
    SELECT rm.`FROM` INTO vUsername
    FROM realtime_message rm
    WHERE rm.uid = pvObjectUid;
    
    SELECT u.id INTO nUserId
    FROM `user` u 
    WHERE u.email = vUsername;
  END IF;
  
 
  -- CASE reaction TO chat channel_id IN collection
  IF ifnull(pnCollectionId, 0) = 0 AND ifnull(pnChannelId, 0) > 0 THEN
    SELECT c.id INTO nCollectionId
    FROM collection c
    WHERE c.channel_id = pnChannelId;
  ELSE 
    SET nCollectionId = pnCollectionId;
  END IF;
  --
 
  --
  INSERT INTO collection_notification
    (user_id, email, collection_id, comment_id, object_uid, object_type, 
    `action`, action_time, assignees, content, kanban_id, created_date, updated_date, channel_id, emoji_unicode)
  VALUES
    (nUserId, vUsername, nCollectionId, CASE WHEN pnAction IN (6, 61, 62, 24) THEN pnCommentId ELSE 0 END, pvObjectUid, pvObjectType
    ,pnAction, pnActionTime, CASE WHEN pnAction IN (17, 18) THEN ifnull(pvAssignee, '') ELSE '' END, ifnull(vContent, ''), pnKanbanID, pnUpdatedDate, pnUpdatedDate, pnChannelId, pvEmojiUnicode);
  --
  SET nNotiID = LAST_INSERT_ID();
 
  -- Only CREATE for owner of chat AND comment
  IF pvObjectType IN ('CHAT', 'COMMENT') THEN
    SET nReturn = n2023_createUserNotification(nNotiID, 0, 0, pnActionTime, pnUpdatedDate, pnUpdatedDate, NULL, nUserId, vUsername);
    -- increase unread badges
    SET nReturn = n2024_increaseNotificationBadge(
      nNotiID,
      nCollectionId,
      pvObjectType,
      pnAction,
      vUsername,
      pvAssignee,
      pnUpdatedDate,
      pnUpdatedDate,
      nUserId,
      vUsername
   );
  ELSE 
      -- CREATE notification for ALL member
      SET nReturn = n2024_afterCreateNotification4SharedCollection(nNotiID,
          nCollectionId, pvObjectType, pnAction, vUsername, pvAssignee, pnActionTime, pnUpdatedDate, pnUpdatedDate);
  END IF;
  
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