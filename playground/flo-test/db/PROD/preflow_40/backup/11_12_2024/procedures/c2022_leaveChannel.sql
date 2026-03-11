CREATE PROCEDURE `c2022_leaveChannel`(pnMemberId     BIGINT(20)
                                                             ,pnUserId       BIGINT(20)
                                                             ,pvItemType     VARBINARY(50)
                                                             ,pdDeletedTime   DOUBLE(13,3))
BEGIN
  --
  --
  DECLARE nchannelId      BIGINT(20) DEFAULT 0;
  DECLARE nCollectionId   BIGINT(20) DEFAULT 0;
  DECLARE vEmail          VARCHAR(100);
  DECLARE vUid            VARCHAR(255);
  DECLARE nMemberId       BIGINT(20) DEFAULT 0;
  DECLARE nUserId         BIGINT(20) DEFAULT 0;
  DECLARE nCount          INTEGER DEFAULT 0;
  DECLARE nRETURN         INTEGER DEFAULT 0;
  DECLARE nRevokeRime     DOUBLE(13,3) DEFAULT 0;
  DECLARE vMTitle         VARCHAR(2000);
  DECLARE vCTitle         VARCHAR(2000);
  -- 1. verify existed member
  SELECT cm.id, cc.uid, cm.channel_id, cc.collection_id, cm.user_id, cm.email, cm.revoke_time
        ,cc.title, cm.title
    INTO nMemberId, vUid, nchannelId, nCollectionId, nUserId, vEmail, nRevokeRime
        ,vCTitle, vMTitle
    FROM conference_member cm
    JOIN conference_channel cc ON (cc.id = cm.channel_id)
   WHERE cm.id = pnMemberId
     AND cm.user_id = pnUserId;
  -- 
  IF ifnull(nMemberId, 0) > 0 THEN
    -- 2. REVOKE member
    DELETE FROM conference_member
     WHERE id = nMemberId
       AND user_id = nUserId;
    -- 3. save TO deleted item
    INSERT INTO deleted_item
          (item_id, item_type, user_id,  item_uid, is_recovery, created_date, updated_date)
    value (nMemberId, pvItemType, nUserId,      vUid,           0,  pdDeletedTime, pdDeletedTime);
    -- 3.5 save TO deleted item FOR member
    SET nRETURN = d2022_genDeletedItemForConferenceMember(nchannelId, nMemberId, nUserId, pdDeletedTime);
    -- 4. remove ALL link
    SET nRETURN = c2022_removeLinkedChannel(vUid, nUserId, pdDeletedTime);
    -- 5. CHECK remove last member
    SELECT count(cm.id)
      INTO nCount
      FROM conference_member cm
     WHERE cm.channel_id = nchannelId;
    -- 5.1. IF this IS last member -> detele channel too
    IF nCount = 0 THEN
      --
      DELETE FROM conference_channel
       WHERE id = nchannelId;
      --
    END IF;
    --
    SELECT nMemberId id, nCount, nchannelId channel_id, nCollectionId collection_id, nUserId user_id
          ,COALESCE(vMTitle, vCTitle, '') title, vEmail email, nRevokeRime revoke_time;
    --
  END IF;
  --
  SELECT 0 id;
  --
END