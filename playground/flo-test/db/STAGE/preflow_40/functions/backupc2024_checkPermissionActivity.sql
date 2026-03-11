CREATE FUNCTION `backupc2024_checkPermissionActivity`(pnCollectionId        BIGINT(20)
                                                                       ,pnKanbanId       BIGINT(20)
                                                                       ,pvObjectUid      VARBINARY(1000)
                                                                       ,pvObjectType     VARBINARY(50)
                                                                       ,pnUserId         BIGINT(20)
                                                                       ) RETURNS TINYINT(1)
BEGIN
  -- CHECK permisstion TO comment OR DELETE comment
  # -6. Link NOT found
  # -5. Object was trashed
  # -4. Collection was trashed
  # -3. NOT allow CHANGE comment FROM the other
  # -2. dont have edit RIGHT: access denied
  # -1. NOT shared collection
  #  0. CREATE | NOT found comment fail
  #  1. allow comment
  #  2. owner of the comment allow UPDATE, DELETE comment
  #  3. collection owner, collection editor permission
  --
  DECLARE nOwnerID           BIGINT(20);
  DECLARE nCommentOwner      BIGINT(20);
  DECLARE nIdLink            BIGINT(20);
  DECLARE nShared            TINYINT(1);
  DECLARE nCollectionType    TINYINT(1);
  DECLARE nReturn            TINYINT(1) DEFAULT 0;
  DECLARE nIsTrashed         TINYINT(1);
  
  -- 0. collection id = 0 aka omni
  IF COALESCE(pnCollectionId, 0) = 0 THEN
    --
    SELECT COALESCE(max(ca.user_id), 0)
      INTO nOwnerID
      FROM collection_activity ca
      WHERE ca.object_uid = pvObjectUid;
    IF nOwnerID = COALESCE(pnUserId, -1) THEN
      --
      RETURN 3;
      --
    END IF;
    --
  END IF;
  -- 1.
  SELECT COALESCE(max(co.user_id), -4), co.`type`, co.is_trashed
    INTO nOwnerID, nCollectionType, nIsTrashed
    FROM collection co
   WHERE co.id = pnCollectionId;
  -- 
  -- 1.1 ..collection DELETE | trashed
  IF nOwnerID = -4 OR COALESCE(nIsTrashed, 0) > 0 THEN
    -- trashed collection
    RETURN -4;
    -- 
  END IF;
  -- 1.2 CHECK collection owner
  IF COALESCE(nCollectionType, 0) <> 3 THEN
    -- NOT shared collection
    RETURN -1;
    -- 
  END IF;
  IF COALESCE(pvObjectUid, '') <> '' THEN
    -- 2. CHECK object trashed?
    SELECT COALESCE(max(tc.id), 0) > 0
      INTO nIsTrashed
      FROM trash_collection tc
     WHERE tc.object_uid = pvObjectUid
       AND tc.user_id = pnUserId;
    -- 
    IF nIsTrashed > 0 THEN
      -- trashed object
      RETURN -5;
      -- 
    END IF;
    -- 3. CHECK link object collection
    IF ifnull(pnKanbanId, 0) > 0 THEN
      --
      SELECT ifnull(max(kk.id), 0)
        INTO nIdLink
        FROM kanban kk
       WHERE kk.id = pnKanbanId
         AND kk.collection_id = pnCollectionId
         AND kk.is_trashed = 0;
      --
    ELSE
      --
      SELECT ifnull(max(lco.id), 0)
        INTO nIdLink
        FROM linked_collection_object lco
       WHERE lco.object_uid = pvObjectUid
         AND lco.collection_id = pnCollectionId
         AND lco.is_trashed = 0;
      -- 
    END IF;
    -- 
    IF nIdLink = 0 THEN
      -- NOT link collection
      RETURN -6;
      -- 
    END IF;
    -- 
  END IF;
  -- 4. CHECK permisstion ON this collection
  IF COALESCE(nOwnerID, 0) = COALESCE(pnUserId, -1) THEN
    -- 4.1. CHECK collection owner
    SET nReturn = 3;
    -- 
  ELSE
    -- 4.2. CHECK member joined
    SELECT COALESCE(max(csm.shared_status), 0)
      INTO nShared
      FROM collection_shared_member csm
     WHERE csm.collection_id = pnCollectionId
       AND csm.member_user_id = pnUserId
       AND csm.access = 2; -- editor only
    -- NOT joined shared collection
    SET nReturn = IF(COALESCE(nShared, 0) = 1, 1, -2);
    --
  END IF;
  --
  RETURN nReturn;
  --
END