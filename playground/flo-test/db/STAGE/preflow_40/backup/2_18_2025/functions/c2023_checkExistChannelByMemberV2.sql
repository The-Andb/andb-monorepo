CREATE FUNCTION `c2023_checkExistChannelByMemberV2`(pnChannelId  BIGINT(20)
                                                                    ,pnUserId     BIGINT(20)) RETURNS VARCHAR(50) CHARSET utf8mb3 COLLATE utf8mb3_unicode_ci
BEGIN
  --
  DECLARE nReturn           TINYINT(1) DEFAULT 0;
  DECLARE nCollectionId     BIGINT(20);
  DECLARE nChannelId        BIGINT(20);
  DECLARE nTrashId        BIGINT(20);
  --
  IF pnChannelId = 0 THEN 
    --
    RETURN concat(nReturn,'##',0);
    --
  END IF;
  --
  SELECT cc.id, cc.collection_id
    INTO nChannelId, nCollectionId
    FROM conference_channel cc
    JOIN conference_member cm ON (cc.id = cm.channel_id)
   WHERE cc.id = pnChannelId
     AND cm.user_id = pnUserId
     AND cm.revoke_time = 0 -- The members IS NOT revoked
     AND cc.is_trashed = 0;
  -- CHECK channel belong TO shared collection?
  IF ifnull(nCollectionId, 0) > 0 THEN
    -- CHECK IS collection trashed?
    SELECT ifnull(max(tc.id), 0)
      INTO nTrashId
      FROM trash_collection tc
     WHERE tc.object_id = nCollectionId
       AND tc.object_type = 'FOLDER';
    --
    IF nTrashId > 0 THEN
      --
      RETURN 0;
      --
    END IF;
    --
  END IF;
  --
  RETURN concat(ifnull(nChannelId, 0) > 0, '##' , ifnull(nCollectionId, 0));
  --
END