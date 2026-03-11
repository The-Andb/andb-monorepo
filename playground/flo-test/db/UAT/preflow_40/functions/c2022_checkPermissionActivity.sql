CREATE DEFINER=`tritv`@`172.29.7.109` FUNCTION `c2022_checkPermissionActivity`(pnCollectionId        BIGINT(20)
                                                                       ,pvObjectUid      VARBINARY(1000)
                                                                       ,pvObjectType     VARBINARY(50)
                                                                       ,pnUserId         BIGINT(20)
                                                                       ) RETURNS TINYINT(1)
BEGIN
  
  
  
  
  
  
  
  
  
  
  
  DECLARE nOwnerID           BIGINT(20);
  DECLARE nCommentOwner      BIGINT(20);
  DECLARE nIdLink            BIGINT(20);
  DECLARE nShared            TINYINT(1);
  DECLARE nCollectionType    TINYINT(1);
  DECLARE nReturn            TINYINT(1) DEFAULT 0;
  DECLARE nIsTrashed         TINYINT(1);
  
  
  IF COALESCE(pnCollectionId, 0) = 0 THEN
    
    SELECT COALESCE(max(ca.user_id), 0)
      INTO nOwnerID
      FROM collection_activity ca
      WHERE ca.object_uid = pvObjectUid;
    IF nOwnerID = COALESCE(pnUserId, -1) THEN
      
      RETURN 3;
      
    END IF;
    
  END IF;
  
  SELECT COALESCE(max(co.user_id), -4), co.`type`, co.is_trashed
    INTO nOwnerID, nCollectionType, nIsTrashed
    FROM collection co
   WHERE co.id = pnCollectionId;
  
  
  IF nOwnerID = -4 OR COALESCE(nIsTrashed, 0) > 0 THEN
    
    RETURN -4;
    
  END IF;
  
  IF COALESCE(nCollectionType, 0) <> 3 THEN
    
    RETURN -1;
    
  END IF;
  IF COALESCE(pvObjectUid, '') <> '' THEN
    
    SELECT COALESCE(max(tc.id), 0) > 0
      INTO nIsTrashed
      FROM trash_collection tc
     WHERE tc.object_uid = pvObjectUid;
    
    IF nIsTrashed > 0 THEN
      
      RETURN -5;
      
    END IF;
    
    SELECT COALESCE(max(lco.id), 0)
      INTO nIdLink
      FROM linked_collection_object lco
     WHERE lco.object_uid = pvObjectUid
       AND lco.collection_id = pnCollectionId
       AND lco.is_trashed = 0;
    
    IF nIdLink = 0 THEN
      
      RETURN -4;
      
    END IF;
    
  END IF;
  
  IF COALESCE(nOwnerID, 0) = COALESCE(pnUserId, -1) THEN
    
    SET nReturn = 3;
    
  ELSE
    
    SELECT COALESCE(max(csm.shared_status), 0)
      INTO nShared
      FROM collection_shared_member csm
     WHERE csm.collection_id = pnCollectionId
       AND csm.member_user_id = pnUserId
       AND csm.access = 2; 
    
    SET nReturn = IF(COALESCE(nShared, 0) = 1, 1, -2);
    
  END IF;
  
  RETURN nReturn;
  
END