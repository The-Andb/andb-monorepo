CREATE FUNCTION `c2023_checkPermissionHistory`(nHistotyId           BIGINT(20)
                                                                      ,collectionId         BIGINT(20)
                                                                      ,objectUid            VARBINARY(1000)
                                                                      ,objectType           VARBINARY(50)
                                                                      ,nUserId              BIGINT(20)
                                                                      ) RETURNS TINYINT(1)
BEGIN
  -- CHECK permistion TO comment OR DELETE comment
  DECLARE nOwnerID           BIGINT(20);
  DECLARE nShared            TINYINT(1);
  DECLARE nCollectionId      BIGINT(20);
  DECLARE nKanbanId          BIGINT(20) DEFAULT 0;
  DECLARE nReturn            TINYINT(1) DEFAULT 0;
  DECLARE nIsTrashed         TINYINT(1);
  --
  -- NOT found anything
  IF nHistotyId = 0 AND collectionId = 0 AND ifnull(objectUid, '') = '' THEN
    --
    RETURN 0;
    --
  END IF;
  --
  IF nHistotyId = 0 THEN
    --
    SET nCollectionId = collectionId;
    --
  ELSE
    --
    SELECT ifnull(max(ca.collection_id), 0), ch.kanban_id
      INTO nCollectionId, nKanbanId
      FROM collection_history ch
      JOIN collection_activity ca ON (ch.collection_activity_id = ca.id)
     WHERE ch.id = nHistotyId;
     --
   END IF;
  --
  /*IF ifnull(ncollectionId, 0) = 0 THEN
    -- Collection NOT found
    RETURN -2;
    -- 
  END IF;*/
  SET nReturn = c2024_checkPermissionActivity(nCollectionId, nKanbanId, objectUid, objectType, nUserId);
  --
  RETURN nReturn;
  --
END