CREATE PROCEDURE `c2024_updateConferenceChannel`(pnMemberId      BIGINT(20)
                                                          ,pnUserId        BIGINT(20)
                                                          ,pvTitle         VARCHAR(2000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
                                                          ,pvShareTitle    VARCHAR(2000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
                                                          ,pvDescription   VARCHAR(5000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
                                                          ,pvAvatar        TEXT
                                                          ,pnVIP           TINYINT(1)
                                                          ,pnStarTime    DOUBLE(13,3)
                                                          ,pvRoomURL       VARCHAR(2000)
                                                          ,pnUpdatedDate   DOUBLE(13,3)
                                                          ,pnEnableChatHistory TINYINT(1))
BEGIN
--
--
  DECLARE nMemberID   BIGINT(20);
  DECLARE nChannelId  BIGINT(20);
  DECLARE isCreator   TINYINT(1);
  -- verify existed member
  SELECT cm.id, cm.channel_id, cm.is_creator
    INTO nMemberID, nChannelId, isCreator
    FROM conference_member cm
   WHERE cm.id = pnMemberId
     AND cm.user_id = pnUserId;
  -- 
  IF ifnull(nMemberID, 0) = 0 THEN
    SELECT 0 id;
  ELSE
    -- UPDATE WHEN supply id
    UPDATE conference_member cp
       SET cp.title            = CASE WHEN ifnull(pvTitle, 'NA') = 'NA' THEN cp.title ELSE pvTitle END
          ,cp.`description`    = CASE WHEN ifnull(pvDescription, 'NA') = 'NA' THEN cp.description ELSE pvDescription END
          ,cp.avatar           = CASE WHEN ifnull(pvAvatar, 'NA') = 'NA' THEN cp.avatar ELSE pvAvatar END
          ,cp.vip              = CASE WHEN ifnull(pnVIP, 'NA') = 'NA' THEN cp.vip ELSE pnVIP END
          ,cp.star_time        = CASE WHEN ifnull(pnStarTime, 'NA') = 'NA' THEN cp.vip ELSE pnStarTime END
          ,cp.updated_date     = pnUpdatedDate
     WHERE cp.id               = pnMemberId
       AND cp.user_id          = pnUserId
       AND cp.channel_id       = nChannelId;
    --
    IF ifnull(isCreator, 0) > 0  THEN
      -- only owner can allow UPDATE room_url, shared title, enable_chat_history
     UPDATE conference_channel cc
        SET cc.room_url             = ifnull(pvRoomURL, cc.room_url)
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
    SELECT cm.id id, cc.room_url
          ,cm.vip, cm.email, cm.is_creator, cc.uid, cm.created_date, cm.updated_date
          ,ifnull(cm.revoke_time,0) revoke_time
          ,nChannelId channel_id
          ,COALESCE(cm.title, cc.title, '') title -- ,cm.title,
          ,cc.title share_title
          ,cc.enable_chat_history
      FROM conference_channel cc
      JOIN conference_member cm ON (cc.id = cm.channel_id)
     WHERE cc.id = nChannelId
       AND cm.id = nMemberId;
    --
  END IF;
END