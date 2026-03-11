CREATE PROCEDURE `c2025_updateConferenceChannel`(
pnMemberId              BIGINT(20)
,pvTitle                 VARCHAR(2000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
,pvShareTitle            VARCHAR(2000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
,pvDescription           VARCHAR(5000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
,pvAvatar                TEXT
,pnVip                   TINYINT(1)
,pvRoomUrl               VARCHAR(2000)
,pnUpdatedDate           DOUBLE(13,3)
,pnEnableChatHistory    TINYINT(1)
,pnChatNoti             TINYINT(1)
,pnCallNoti             TINYINT(1)
,pnUserId                BIGINT(20)
,pvEmail                VARCHAR(100))
BEGIN
--
--
  DECLARE nMemberID           BIGINT(20);
  DECLARE nChannelId          BIGINT(20);
  DECLARE isCreator           TINYINT(1);
  DECLARE vOldShareTitle           VARCHAR(5000);
  DECLARE vOldRoomUrl           VARCHAR(2000);
  DECLARE nOldEnableChatHistory   TINYINT(1);
  
  -- verify existed member
  SELECT cm.id, cm.channel_id, cm.is_creator, cc.title, cc.room_url, cc.enable_chat_history
    INTO nMemberID, nChannelId, isCreator, vOldShareTitle, vOldRoomUrl, nOldEnableChatHistory
    FROM conference_member cm
    JOIN conference_channel cc ON (cc.id = cm.channel_id)
   WHERE cm.id = pnMemberId
     AND cm.user_id = pnUserId;
  -- 
  IF ifnull(nMemberID, 0) = 0 THEN
    SELECT 0 id;
  ELSE
    -- UPDATE WHEN supply id
    UPDATE conference_member cp
       SET cp.title             = COALESCE(pvTitle, cp.title)
          ,cp.description       = COALESCE(pvDescription, cp.description)
          ,cp.avatar            = COALESCE(pvAvatar, cp.avatar)
          ,cp.vip               = COALESCE(pnVip, cp.vip)
          ,cp.notification_chat = COALESCE(pnChatNoti, cp.notification_chat)
          ,cp.notification_call = COALESCE(pnCallNoti, cp.notification_call) 
          ,cp.updated_date      = pnUpdatedDate
     WHERE cp.id                = pnMemberId
       AND cp.user_id           = pnUserId
       AND cp.channel_id        = nChannelId;
    -- only UPDATE IF at least 1 channel field IS updated
    IF (ifnull(isCreator, 0) > 0
    AND (
      ifnull(pvShareTitle, 'NA') <> 'NA'
      OR ifnull(pvRoomUrl, 'NA') <> 'NA'
            OR ifnull(pnEnableChatHistory, 'NA') <> 'NA'
    )
     ) THEN
      -- only owner can allow UPDATE room_url, shared title, enable_chat_history
     UPDATE conference_channel cc
        SET cc.room_url             = ifnull(pvRoomUrl, cc.room_url)
           ,cc.enable_chat_history  = COALESCE(pnEnableChatHistory, cc.enable_chat_history, 1)
           ,cc.title                = ifnull(pvShareTitle, cc.title)
           ,cc.updated_date         = pnUpdatedDate
        WHERE cc.id = nChannelId;
      -- updated realtime channel title
      UPDATE realtime_channel rc
         SET rc.title = COALESCE(pvShareTitle, rc.title)
       WHERE rc.type = 1 -- CONFERNECE
         AND rc.internal_channel_id = nChannelId;         
      --
    END IF;
    --
    SELECT cm.id id, cm.vip, cm.email, cm.is_creator, cm.created_date, cm.updated_date, cm.description
          ,cc.room_url, cc.uid, cc.title share_title, cc.enable_chat_history
          ,cm.notification_chat, cm.notification_call
      ,nChannelId channel_id
          ,ifnull(cm.revoke_time,0) revoke_time
      ,COALESCE(cm.title, cc.title, '') title -- ,cm.title,
          ,vOldShareTitle old_share_title
          ,vOldRoomUrl old_room_url
          ,nOldEnableChatHistory old_enable_chat_history
    FROM conference_channel cc
    JOIN conference_member cm ON (cc.id = cm.channel_id)
   WHERE cc.id = nChannelId
     AND cm.id = nMemberId;
    --
  END IF;
END