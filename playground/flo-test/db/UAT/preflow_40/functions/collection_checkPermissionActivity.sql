CREATE DEFINER=`tritv`@`172.29.7.109` FUNCTION `collection_checkPermissionActivity`(nCollectionId        BIGINT(20)
                                                                       ,vObjectUid           VARBINARY(1000)
                                                                       ,nUserId              BIGINT(20)
                                                                       ) RETURNS TINYINT(1)
BEGIN
  
  
  
  
  
  
  
  
  
  
  
  DECLARE nOwnerID           BIGINT(20);
  DECLARE nCommentOwner      BIGINT(20);
  DECLARE nIdLink            BIGINT(20);
  DECLARE nShared            TINYINT(1);
  DECLARE nCollectionType    TINYINT(1);
  DECLARE nReturn            TINYINT(1) DEFAULT 0;
  DECLARE nIsTrashed         TINYINT(1);
  
  IF ifnull(nCollectionId, 0) = 0 THEN
    
    SELECT max(ca.user_id)
      INTO nOwnerID
      FROM collection_activity ca
      WHERE ca.object_uid = vObjectUid;
    IF ifnull(nOwnerID, 0) = ifnull(nUserId, -1) THEN
      
      RETURN 3;
      
    END IF;
    
  END IF;
  
  SELECT ifnull(max(co.user_id), -4), co.`type`, co.is_trashed
    INTO nOwnerID, nCollectionType, nIsTrashed
    FROM collection co
   WHERE co.id = nCollectionId;
  
    
  IF nOwnerID = -4 OR ifnull(nIsTrashed, 0) > 0 THEN
    
    RETURN -4;
    
  END IF;
  
  IF ifnull(nCollectionType, 0) <> 3 THEN
    
    RETURN -1;
    
  END IF;
  IF ifnull(vObjectUid, '') <> '' THEN
    
    SELECT ifnull(tc.id, 0) > 0
      INTO nIsTrashed
      FROM trash_collection tc
     WHERE tc.object_uid = vObjectUid;
    
    IF ifnull(nIsTrashed, 0) > 0 THEN
      
      RETURN -5;
      
    END IF;
    
    SELECT ifnull(max(lco.id),0)
      INTO nIdLink
      FROM linked_collection_object lco
     WHERE lco.object_uid = vObjectUid
       AND lco.collection_id = nCollectionId
       AND lco.is_trashed = 0;
    
    IF nIdLink = 0 THEN
      
      RETURN -4;
      
    END IF;
    
  END IF;
  
  IF ifnull(nOwnerID, 0) = ifnull(nUserId, -1) THEN
    
    SET nReturn = 3;
    
  ELSE
    
    SELECT csm.shared_status
      INTO nShared
      FROM collection_shared_member csm
     WHERE csm.collection_id = nCollectionId
       AND csm.member_user_id = nUserId
       AND csm.access = 2; 
    
    SET nReturn = IF(ifnull(nShared, 0) = 1, 1, -2);
    
  END IF;
  
  RETURN nReturn;
  
END