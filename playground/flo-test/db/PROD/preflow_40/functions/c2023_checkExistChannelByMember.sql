CREATE FUNCTION `c2023_checkExistChannelByMember`(pnChannelId  BIGINT(20)
                                                                    ,pnUserId     BIGINT(20)) RETURNS INT
BEGIN
  --
  DECLARE nReturn           TINYINT(1) DEFAULT 0;
  DECLARE nCollectionId     BIGINT(20);
  DECLARE nChannelId        BIGINT(20);
  DECLARE nTrashId        BIGINT(20);
  --
  IF pnChannelId = 0 THEN 
    --
    RETURN nReturn;
    --
  END IF;
  --
  SELECT cc.id, cc.collection_id
    INTO nChannelId, nCollectionId
    FROM conference_channel cc
    JOIN conference_member cm ON (cc.id = cm.channel_id)
   WHERE cc.id = pnChannelId
     AND cm.user_id = pnUserId
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
  RETURN ifnull(nChannelId, 0) > 0;
  --
END