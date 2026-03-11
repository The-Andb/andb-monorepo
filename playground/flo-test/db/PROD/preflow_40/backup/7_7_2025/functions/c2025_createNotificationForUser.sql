CREATE FUNCTION `c2025_createNotificationForUser`(pnUserId             BIGINT(20)
                                                          ,pvUsername            VARCHAR(255)
                                                          ,pnCollectionId        BIGINT(20)
                                                          ,pnCommentId           INT(11)
                                                          ,pvObjectUid           VARBINARY(1000)
                                                          ,pvObjectType          VARBINARY(50)
                                                          ,pnAction              INT(11)
                                                          ,pnActionTime          DOUBLE(13,3)
                                                          ,pvContent             VARCHAR(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
                                                          ,pnChannelId           BIGINT(20)
                                                          ,pvEmojiUnicode        VARCHAR(100)
                                                          ,pnUpdatedDate         DOUBLE(13,3)
                                                          ,pnAccountId           BIGINT(20)
                                                          ) RETURNS BIGINT
BEGIN
  --
  DECLARE nReturn           INT DEFAULT 0;
  DECLARE vObjectType       VARBINARY(50);
  DECLARE nNotiID           BIGINT(20) DEFAULT 0;
  DECLARE nCollectionId     BIGINT(20) DEFAULT ifnull(pnCollectionId, 0);
  DECLARE nOwnerUserId      BIGINT(20) DEFAULT ifnull(pnUserId, 0);
  DECLARE vOwnerEmail       VARCHAR(255) DEFAULT ifnull(pvUsername, '');
  DECLARE nRole             INT DEFAULT 0;
  DECLARE nCategory         TINYINT DEFAULT 0;
  DECLARE vObjectUid    VARBINARY(1000) DEFAULT ifnull(pvObjectUid, '');
 
  -- Only CREATE for owner
  IF ifnull(pvObjectType, '') = 'CHAT' AND ifnull(pnAction, 0) = 23 THEN
    --
    SELECT u.id, u.email
    INTO nOwnerUserId, vOwnerEmail
    FROM realtime_message rm
    JOIN user u ON u.username = rm.`FROM`
    WHERE rm.uid = pvObjectUid;
    --
  END IF;
 
 -- Only CREATE for owner comment
  IF ifnull(pvObjectType, '') = 'COMMENT' AND ifnull(pnAction, 0) = 24 THEN
    SELECT cc.user_id, cc.email, ca.object_type, ca.object_uid, ifnull(ct.category, 0)
      INTO nOwnerUserId, vOwnerEmail, vObjectType, vObjectUid, nCategory
      FROM collection_comment cc
      JOIN collection_activity ca ON (cc.collection_activity_id = ca.id)
 LEFT JOIN cal_todo ct ON ca.object_type = 'VTODO' AND ca.object_uid = ct.uid 
     WHERE cc.id = pnCommentId;
  END IF;
 
  -- CASE reaction TO chat channel_id IN collection
  IF nCollectionId = 0 AND ifnull(pnChannelId, 0) > 0 THEN
    --
    SELECT c.id 
      INTO nCollectionId
      FROM collection c
     WHERE c.channel_id = pnChannelId;
    --
    --
    IF ifnull(nCollectionId, 0) > 0 THEN
      -- Don't CREATE noti for chat owner WITH viewer role OR NOT permisstion
      SET nRole = c2023_checkCollectionPermissionV2(nCollectionId, 0, nOwnerUserId);
      IF nRole <= 1 THEN
        RETURN 0;
      END IF;
      --
    END IF;
  END IF;
  --
  INSERT INTO collection_notification
    (user_id, email, actor, collection_id, comment_id, object_uid, object_type, 
    `action`, action_time, assignees, content, kanban_id, created_date, updated_date, channel_id, emoji_unicode, account_id, category)
  VALUES
    (nOwnerUserId, vOwnerEmail, pvUsername, nCollectionId, pnCommentId, ifnull(vObjectUid, pvObjectUid), ifnull(vObjectType, pvObjectType)
    ,pnAction, pnActionTime, '', ifnull(pvContent, ''), 0, pnUpdatedDate, pnUpdatedDate, pnChannelId, pvEmojiUnicode, pnAccountId, nCategory);
  --
  SET nNotiID = LAST_INSERT_ID();
  --
  -- CREATE user notification FOR tracking
  SET nReturn = n2023_createUserNotification(nNotiID, 0, 0, pnActionTime, pnUpdatedDate, pnUpdatedDate, NULL, nOwnerUserId, vOwnerEmail);
  -- increase unread badges
  SET nReturn = n2024_increaseNotificationBadge(
    nNotiID,
    nCollectionId,
    pvObjectType,
    pnAction,
    '',
    '',
    pnUpdatedDate,
    pnUpdatedDate,
    nOwnerUserId,
    vOwnerEmail
  );
  --
  RETURN nNotiID;
  --
END