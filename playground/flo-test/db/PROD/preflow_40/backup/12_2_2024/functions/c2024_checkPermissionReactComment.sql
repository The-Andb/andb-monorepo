CREATE FUNCTION `c2024_checkPermissionReactComment`(pnCommentId           BIGINT(20)
                                                                      ,pnUserId              BIGINT(20)
                                                                      ) RETURNS TINYINT(1)
BEGIN
  -- CHECK permistion TO comment OR DELETE comment
  DECLARE nCommentId         BIGINT(20);
  DECLARE nCommentOwner      BIGINT(20);
  DECLARE nCollectionId      BIGINT(20);
  DECLARE nCollectionType    TINYINT(1);
  DECLARE nReturn            TINYINT(1) DEFAULT 0;
  DECLARE nIsTrashed         TINYINT(1);
  DECLARE vObjectUid         VARBINARY(1000);
  DECLARE vObjectType        VARBINARY(50);
  -- NOT found anything
  IF ifnull(pnCommentId, 0) = 0 OR ifnull(pnUserId, 0) = 0 THEN
    --
    RETURN 0;
    --
  END IF;
  -- CHECK owner comment
  SELECT ifnull(max(cm.id),0), ifnull(max(cm.user_id),0)
    INTO nCommentId, nCommentOwner
    FROM collection_comment cm
   WHERE cm.id = pnCommentId;
  -- Comment NOT found
  IF nCommentId = 0 THEN
    --
    RETURN 0;
    --
  END IF;
  --
  SELECT ca.collection_id, ca.object_uid, ca.object_type
    INTO nCollectionId, vObjectUid, vObjectType
    FROM collection_comment cc
    JOIN collection_activity ca ON (cc.collection_activity_id = ca.id)
   WHERE cc.id = nCommentId;
  -- 
  SET nReturn = c2022_checkPermissionActivity(nCollectionId, vObjectUid, vObjectType, pnUserId);
  --
  IF nReturn > 0 AND pnUserId = nCommentOwner THEN
    -- comment owner
    RETURN 2;
    --
  END IF;
  --
  RETURN nReturn;
  --
END