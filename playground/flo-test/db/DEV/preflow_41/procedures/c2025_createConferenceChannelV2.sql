CREATE PROCEDURE `c2025_createConferenceChannelV2`(
pnUserId         BIGINT(20)
,pnCollectionId    BIGINT(20)
,pvUid           VARBINARY(1000)
,pvEmail         VARCHAR(100)
,pvTitle         VARCHAR(2000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
,pvShareTitle    VARCHAR(2000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
,pvDescription   VARCHAR(5000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
,pvAvatar        TEXT
,pnVip           TINYINT(1)
,pnNotificationChat TINYINT(1)
,pnNotificationCall TINYINT(1)
,pvRoomUrl       VARCHAR(2000)
,pnCreatedDate   DOUBLE(13,3)
,pnUpdatedDate   DOUBLE(13,3)
,pnEnableChatHistory TINYINT(1))
BEGIN
  --
  DECLARE nchannelId             BIGINT(20) DEFAULT 0;
  DECLARE nMemberId              BIGINT(20) DEFAULT 0;
  DECLARE nEnableChatHistory     BIGINT(20) DEFAULT ifnull(pnEnableChatHistory, 1);
  -- START TRANSACTION;
  --
  --
  --
  -- CHECK existed creator
    # CREATE new WHEN no id supply
     INSERT INTO conference_channel
    (user_id, collection_id, title, uid, room_url, enable_chat_history, created_date, updated_date, last_used)
    VALUES
    (pnUserId, IF(ifnull(pnCollectionId, 0) = 0, NULL, pnCollectionId)
    ,COALESCE(pvShareTitle, pvTitle, ''), pvUid, ifnull(pvRoomUrl, ''), nEnableChatHistory, pnCreatedDate, pnUpdatedDate, pnUpdatedDate);
    #
    SELECT LAST_INSERT_ID() INTO nchannelId;
    IF ifnull(nchannelId, 0) = 0 THEN
     -- ROLLBACK;
      SELECT 0;
    END IF;
      --
    INSERT INTO conference_member
      (user_id, channel_id, email, created_by, is_creator, title, 
      description, avatar, vip, view_chat_history, chat_url, notification_chat, notification_call, join_time, created_date,    updated_date, last_missed_call)
    VALUES
      (pnUserId, nchannelId, pvEmail, pvEmail, 1, ifnull(pvTitle, ''), 
      pvDescription, pvAvatar, ifnull(pnVip, 0), nEnableChatHistory, '',ifnull(pnNotificationChat, 2),ifnull(pnNotificationCall, 1), pnCreatedDate, pnCreatedDate, pnUpdatedDate, 0);
    -- ON DUPLICATE KEY UPDATE updated_date = unix_timestamp();
    SELECT LAST_INSERT_ID() INTO nMemberId;
    -- handle collection
    IF ifnull(pnCollectionId, 0) > 0 THEN
      --
      UPDATE collection co
         SET co.channel_id = nchannelId
       WHERE co.id = pnCollectionId
         AND co.user_id = pnUserId;
      --
    END IF;
  #
  SELECT nchannelId channel_id, nMemberId memberId;
    --
    -- COMMIT;
END