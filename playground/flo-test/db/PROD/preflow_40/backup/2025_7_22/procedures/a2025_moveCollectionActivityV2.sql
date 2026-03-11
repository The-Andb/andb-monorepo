CREATE PROCEDURE `a2025_moveCollectionActivityV2`(
pnCollectionActivityId  BIGINT(20)
,pnCollectionId       BIGINT(20)
,pvObjectUid          VARBINARY(1000)
,pnUserId             BIGINT(20)
,pvUserEmail          VARCHAR(255)
,pvContent            VARCHAR(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
,pnActionTime         DOUBLE(13,3)
,pdUpdatedDate        DOUBLE(13,3))
BEGIN
  --
  DECLARE nCollectionId      BIGINT(20) DEFAULT -1;
  DECLARE nUpdatedDate       DOUBLE(13,3) DEFAULT -1;
  DECLARE outNotiYDate       DOUBLE(13,3);
  DECLARE oldObjectUid       VARBINARY(1000);
  DECLARE vObjectType        VARCHAR(200) DEFAULT '';
  DECLARE countMax           BIGINT(20) DEFAULT -1;
  DECLARE nID                BIGINT(20) DEFAULT -1;
  DECLARE bHasComment        INT DEFAULT 0;
  DECLARE outNotiX           BIGINT(20) DEFAULT 0;
  DECLARE outNotiY           BIGINT(20) DEFAULT 0;
  DECLARE vContent           VARCHAR(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
  DECLARE nCategory          INT DEFAULT 0;
  DECLARE nUserId            BIGINT(20);
  DECLARE vUserEmail         VARCHAR(255);
  DECLARE vObjectHref        VARCHAR(200) DEFAULT '';
  DECLARE calendarUriSource  VARCHAR(255) DEFAULT '';
  DECLARE calendarUriDest    VARCHAR(255) DEFAULT '';
  DECLARE calendarUriMember  VARCHAR(255) DEFAULT '';
  DECLARE calendarUri        VARCHAR(255) DEFAULT '';
  DECLARE nOldCollectionId   BIGINT(20)   DEFAULT -1;
  -- 
  SET bHasComment = 0;
  -- move object TO omni
  IF pnCollectionId = 0 THEN
    -- 
    SELECT ca.old_collection_id, ca.object_type, ca.object_uid, st.omni_cal_id, ifnull(ct.category, ca.category)
      INTO nCollectionId, vObjectType, oldObjectUid, calendarUriSource, nCategory
      FROM collection_activity ca
      JOIN setting AS st ON st.user_id = pnUserId
 LEFT JOIN cal_todo ct ON ca.object_type = "VTODO" AND ct.uid = ca.object_uid
     WHERE ca.id = pnCollectionActivityId 
       AND ca.user_id = pnUserId
     ORDER BY ct.id DESC
     LIMIT 1;
    -- 
  ELSE
  
   -- fix move object FROM omni back TO share collection 
   SELECT IF(ca.old_collection_id <> 0, ca.old_collection_id, pnCollectionId)
     INTO nOldCollectionId
     FROM collection_activity ca 
    WHERE ca.id = pnCollectionActivityId
      AND ca.user_id = pnUserId;
  
    -- GET owner info dest collection
    SELECT ca.old_collection_id, ca.object_type, ca.object_uid, c.calendar_uri, ifnull(ct.category, ca.category)
      INTO nCollectionId, vObjectType, oldObjectUid, calendarUriSource, nCategory
      FROM collection_activity ca
      JOIN collection c ON c.id = nOldCollectionId
 LEFT JOIN cal_todo ct ON ca.object_type = "VTODO" AND ct.uid = ca.object_uid
     WHERE ca.id = pnCollectionActivityId
       AND ca.user_id = pnUserId
     ORDER BY ct.id DESC
     LIMIT 1;
    -- 
  END IF;

  IF (nCollectionId >= 0 AND nCollectionId <> pnCollectionId) THEN
  
    -- move object TO omni
    IF pnCollectionId = 0 THEN
      SET nUserId = pnUserId;
      SET vUserEmail = pvUserEmail;
      SET calendarUriDest = calendarUriSource;
    ELSE
       -- GET owner of collection dest
     SELECT u.id, u.email, c.calendar_uri
       INTO nUserId, vUserEmail, calendarUriDest
       FROM collection c
       JOIN `user` u ON c.user_id = u.id
      WHERE c.id = pnCollectionId;
       
      -- GET calendar_uri of the member
     SELECT csm.calendar_uri
       INTO calendarUriMember
       FROM collection_shared_member csm
      WHERE csm.collection_id = pnCollectionId
        AND csm.member_user_id = pnUserId
        AND csm.shared_status = 1
        AND csm.access = 2;
    END IF;
     
     -- href response api
   IF ifnull(vObjectType, '') <> 'URL' THEN
     -- 
     SET calendarUri = IF(calendarUriMember <> '', calendarUriMember, calendarUriDest);
     -- 
   END IF;
   --
  
     -- IF has activity
     -- count
     SELECT count(*)
      INTO countMax 
      FROM collection_history ch 
     WHERE ch.collection_activity_id = pnCollectionActivityId;
     --
     SET nUpdatedDate = ROUND(pdUpdatedDate + (countMax + 1 ) * 0.001, 3);
     --
     UPDATE collection_activity ca 
        SET ca.collection_id     = pnCollectionId
           ,ca.old_collection_id = pnCollectionId
           ,ca.object_uid        = pvObjectUid
           ,ca.object_href       = CONCAT('/calendarserver.php/calendars/', vUserEmail, '/', calendarUriDest,'/',pvObjectUid,'.ics')
           ,ca.updated_date      = nUpdatedDate
           ,ca.user_id       = nUserId
      WHERE ca.id = pnCollectionActivityId;
     -- CREATE notification 
     CALL c2025_createNotiWhenMoveV2(outNotiX, outNotiY, outNotiYDate, vContent
                                  ,nCollectionId, pnCollectionId, oldObjectUid
                                  ,pvObjectUid, vObjectType, pvContent, pnActionTime, nUpdatedDate);

     -- UPDATE ALL history, comment
     SET bHasComment = a2024_afterMoveCollectionActivity(pnCollectionActivityId, nUpdatedDate);
    --
  END IF;
     
  -- 
  IF ifnull(vObjectType, '') <> 'URL' THEN
    -- 
    SET vObjectHref = CONCAT('/calendarserver.php/calendars/', pvUserEmail, '/', IF(calendarUri <> '', calendarUri, calendarUriSource),'/',pvObjectUid,'.ics');
    -- 
  END IF;
  -- 
     
  -- RETURN VALUES  
  SELECT bHasComment has_comment
        ,nCollectionId collection_id
        ,vObjectHref object_href
        ,vContent object_title
        ,nUpdatedDate max_updated_date
        ,vObjectType object_type
        ,outNotiX source_noti_id
        ,outNotiY dest_noti_id
        ,outNotiYDate updated_date
        ,CONVERT(oldObjectUid USING cp1251) object_uid_old
        ,nCategory category
        ,pvUserEmail email
        ;
END