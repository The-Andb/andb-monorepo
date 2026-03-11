CREATE FUNCTION `c2024_createNotificationForChat`(pnChannelId           BIGINT(20)
                                                                    ,pnUserId             BIGINT(20)
                                                                    ,pvUsername            VARCHAR(255)                                                                    
                                                                    ,pvObjectUid           VARBINARY(1000)
                                                                    ,pvObjectType          VARBINARY(50)
                                                                    ,pvContent             VARCHAR(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
                                                                    ,pvMentionList         TEXT -- anb@dm.xc,anb@dm.xc
                                                                    ,pnAction              INT(11) -- 23: CHAT, 25: EDIT CHAT
                                                                    ,pnActionTime          DOUBLE(13,3)
                                                                    ,pnUpdatedDate         DOUBLE(13,3)
                                                                    ) RETURNS BIGINT
BEGIN
  --
  DECLARE nReturn       INT DEFAULT 0;
  DECLARE nNotiID       BIGINT(20) DEFAULT 0;
  DECLARE vContent      VARCHAR(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
  DECLARE nCollectionId BIGINT(20) DEFAULT 0;
  --
  SET vContent = ifnull(pvContent, ''); 
  -- CASE reaction TO chat channel_id IN collection 
  SELECT c.id INTO nCollectionId
    FROM collection c
   WHERE c.channel_id = pnChannelId;
  --
  INSERT INTO collection_notification
    (user_id, email, collection_id, object_uid, object_type, 
    `action`, action_time, content, assignees, created_date, updated_date, channel_id)
  VALUES
    (pnUserId, pvUsername, nCollectionId, pvObjectUid, pvObjectType
    ,pnAction, pnActionTime, ifnull(vContent, ''), '', pnUpdatedDate, pnUpdatedDate, pnChannelId);
  --
  SET nNotiID = LAST_INSERT_ID();
 
--   -- Only CREATE for owner of chat AND comment
--   IF pvObjectType IN ('CHAT', 'COMMENT') THEN
--     SET nReturn = n2023_createUserNotification(nNotiID, 1, 0, pnActionTime, pnUpdatedDate, pnUpdatedDate, NULL, pnUserId, pvUsername);
--     -- increase unread badges
--     SET nReturn = n2024_increaseNotificationBadge(
--       nNotiID,
--       nCollectionId,
--       pvObjectType,
--       pnAction,
--       '', -- pvAssigner     
--       '', -- pvAssignees 
--       pnUpdatedDate,
--       pnUpdatedDate,
--       pnUserId,
--       pvUsername
--    );
--   ELSE 
--       -- CREATE notification for ALL member
--       SET nReturn = n2024_afterCreateNotification4SharedCollection(nNotiID,
--           nCollectionId, pvObjectType, pnAction, pvUsername, pvAssignee, pnActionTime, pnUpdatedDate, pnUpdatedDate);
--   END IF;


  -- CREATE notification for ALL member
  SET nReturn = n2025_afterCreateNotification4Conference(nNotiID, nCollectionId, pnChannelId, pvObjectType, pnAction, pnActionTime, pnUpdatedDate, pnUpdatedDate);
    -- increase unread badges
    SET nReturn = n2024_increaseNotificationBadge(
      nNotiID,
      nCollectionId,
      pvObjectType,
      pnAction,
      '', -- pvAssigner     
      '', -- pvAssignees 
      pnUpdatedDate,
      pnUpdatedDate,
      pnUserId,
      pvUsername
   );

  -- only for chat
  IF pnAction = 30 AND ifnull(pvMentionList, '') <> ''THEN
    --
    SET nReturn = n2024_considerMentionInNotificationForChatV3(NULL, nNotiID, pnUserId, pvObjectUid, pvObjectType, pvMentionList, pnActionTime, pnUpdatedDate);
    -- 
  END IF;
  --
  RETURN nNotiID;
  --
END