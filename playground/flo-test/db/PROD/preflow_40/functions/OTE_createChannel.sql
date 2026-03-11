CREATE FUNCTION `OTE_createChannel`(
pnUserId         BIGINT(20)
,pnCollectionId  BIGINT(20)
,pvUid           VARBINARY(1000)
,pvEmail         VARCHAR(100)
,pvTitle         VARCHAR(2000) CHARACTER SET latin1 COLLATE latin1_swedish_ci
,pnCreatedDate   DOUBLE(13,3)
,pnUpdatedDate   DOUBLE(13,3)
) RETURNS BIGINT
BEGIN
  --
  DECLARE nchannelId             BIGINT(20) DEFAULT 0;
  DECLARE nMemberId              BIGINT(20) DEFAULT 0;
  --
  INSERT INTO conference_channel
    (user_id, collection_id, title, uid, room_url, enable_chat_history, created_date, updated_date, last_used)
  VALUES
    (pnUserId, pnCollectionId
    ,pvTitle, pvUid, '', NULL, pnCreatedDate, pnUpdatedDate, pnUpdatedDate)
    ON DUPLICATE KEY UPDATE updated_date = unix_timestamp();
    #
  SELECT LAST_INSERT_ID() INTO nchannelId;
  --
  IF ifnull(nchannelId, 0) = 0 THEN
      RETURN 0;
    END IF;
      --
    INSERT INTO conference_member
      (user_id, channel_id, email, created_by, is_creator, title, 
      description, avatar, vip, view_chat_history, chat_url, join_time, created_date,    updated_date)
    VALUES
      (pnUserId, nchannelId, pvEmail, pvEmail, 1, pvTitle, 
      NULL, NULL, 0, NULL, '', pnCreatedDate, pnCreatedDate, pnUpdatedDate);
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
  RETURN nchannelId;
    --
    -- COMMIT;
END