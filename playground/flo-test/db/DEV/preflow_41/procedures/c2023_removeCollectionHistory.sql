CREATE PROCEDURE `c2023_removeCollectionHistory`(pnID                  BIGINT(20)
                                                             ,pnUserId               BIGINT(20)
                                                             ,pnDeleteTime            DOUBLE(13,3))
sp_removeHistory:BEGIN
  --
  DECLARE nPermission    TINYINT(1) DEFAULT 0;
  DECLARE nIDHistory     BIGINT(20) DEFAULT 0;
  DECLARE nCollectionId  BIGINT(20) DEFAULT 0;
  DECLARE nUserId        BIGINT(20) DEFAULT 0;
  DECLARE vObjectUid     VARBINARY(1000) DEFAULT 0;
  DECLARE vObjectType    VARBINARY(50) DEFAULT 0;
  DECLARE vReturn        VARCHAR(255) DEFAULT 0;
  DECLARE nCAID          BIGINT(20) DEFAULT 0;
  DECLARE nReturn        INT(20) DEFAULT 0;
  DECLARE vEmail         VARCHAR(255) DEFAULT '';
   --
  SELECT ch.id, ca.collection_id, ca.object_uid, ca.object_type, ca.id, ch.email
      INTO nIDHistory, nCollectionId, vObjectUid, vObjectType, nCAID, vEmail
      FROM collection_history ch
      JOIN collection_activity ca ON (ca.id = ch.collection_activity_id)
    WHERE ch.id = pnID;
  --
  IF ifnull(nIDHistory, 0) = 0 THEN
    --
    SELECT 0 id;
    LEAVE sp_removeHistory;
    --
  END IF;
  -- 1. CHECK permission
  SET nPermission = c2023_checkPermissionHistory(nIDHistory, nCollectionId, vObjectUid, vObjectType, pnUserId);
  -- -4: link NOT found still allow delele
  IF nPermission < 2 AND nPermission <> -6 THEN
    --
    SELECT (CASE WHEN nPermission < 1 THEN nPermission ELSE -3 END) id;
    LEAVE sp_removeHistory;
    --
  END IF;
  -- 2.
  -- SELECT ch.id, ca.collection_id
  --  INTO nIDHistory, nCollectionId
  --  FROM collection_history ch
  --  JOIN collection_activity ca ON (ca.id = ch.collection_activity_id)
  -- WHERE ch.id = nID;
  --
  IF ifnull(nIDHistory, 0) > 0 THEN
    --
    DELETE FROM collection_history
    WHERE id = nIDHistory;
    -- 3. save TO deleted item
    IF ifnull(nCollectionId, 0) = 0 THEN
      -- omni INSERT only FOR owner
      INSERT INTO deleted_item
        (item_id, item_type, user_id,  item_uid, is_recovery, created_date, updated_date)
      value (pnID, 'COLLECTION_HISTORY', pnUserId,      '',           0,  pnDeleteTime, pnDeleteTime);
      --
    ELSE
      -- normal INSERT FOR ALL member IN collection shared
      SELECT co.user_id
        INTO nUserId
        FROM collection co
       WHERE co.id = nCollectionId;
      --
      SET nReturn = d2022_generateDeletedItemSharedOmni('COLLECTION_HISTORY', nCollectionId, pnID, pnDeleteTime, nUserId);
      --
    END IF;
  END IF;
  
  SELECT nIDHistory id, nCollectionId collection_id;
  --
END