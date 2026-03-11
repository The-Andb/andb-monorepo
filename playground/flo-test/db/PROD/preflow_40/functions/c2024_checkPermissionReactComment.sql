CREATE FUNCTION `c2024_checkPermissionReactComment`(pnCollectionId        BIGINT(20)
                                                                      ,pnUserId              BIGINT(20)
                                                                      ) RETURNS TINYINT(1)
BEGIN
 -- CHECK permisstion TO comment OR DELETE comment
  # -4. Collection was trashed
  # -3. NOT allow CHANGE comment FROM the other
  # -2. dont have edit RIGHT: access denied
  # -1. NOT shared collection
  #  0. CREATE | NOT found comment fail
  #  1. allow reaction
  #  2. owner of the comment
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
  IF ifnull(pnCollectionId, 0) = 0 OR ifnull(pnUserId, 0) = 0 THEN
    --
    RETURN -1;
    --
  END IF;
  -- 1.
  SELECT COALESCE(max(co.user_id), -4), co.`type`, co.is_trashed
    INTO nOwnerID, nCollectionType, nIsTrashed
    FROM collection co
   WHERE co.id = pnCollectionId;
  -- 
  -- 1.1 ..collection DELETE | trashed
  IF nOwnerID = -4 OR ifnull(nIsTrashed, 0) > 0 THEN
    -- trashed collection
    RETURN -4;
    -- 
  END IF;
  -- 1.2 CHECK collection owner
  IF ifnull(nCollectionType, 0) <> 3 THEN
    -- NOT shared collection
    RETURN -1;
    -- 
  END IF;
 
  -- 4. CHECK permisstion ON this collection
  IF ifnull(nOwnerID, 0) = ifnull(pnUserId, -1) THEN
    -- 4.1. CHECK collection owner
    SET nReturn = 3;
    -- 
  ELSE
    -- 4.2. CHECK member joined
    SELECT ifnull(max(csm.shared_status), 0)
      INTO nShared
      FROM collection_shared_member csm
     WHERE csm.collection_id = pnCollectionId
       AND csm.member_user_id = pnUserId
       AND csm.access IN (0,1,2) -- owner, READ, READ_WRITE
       AND csm.shared_status = 1; -- joined only
    -- NOT joined shared collection
    SET nReturn = IF(ifnull(nShared, 0) = 1, 1, -2);
    --
  END IF;
  --
  RETURN nReturn;
  --
END