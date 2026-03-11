CREATE PROCEDURE `a2024_moveCollectionActivity`(
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
  DECLARE vObjectHref        VARCHAR(200) DEFAULT '';
  DECLARE nUpdatedDate       DOUBLE(13,3) DEFAULT -1;
  DECLARE outNotiYDate       DOUBLE(13,3);
  DECLARE oldObjectUid       VARBINARY(1000);
  DECLARE vObjectType        VARCHAR(200) DEFAULT '';  
  DECLARE vObjectTitle       VARCHAR(255);
  DECLARE calendarUri        VARCHAR(255) DEFAULT '';
  DECLARE countMax           BIGINT(20) DEFAULT -1;
  DECLARE nID                BIGINT(20) DEFAULT -1;
  DECLARE nDateItemHistory   DOUBLE(13,3);
  DECLARE nDateItemComment   DOUBLE(13,3);
  DECLARE vTable             VARCHAR(255);
  DECLARE bHasComment        INT DEFAULT 0;
  DECLARE nReturn            INT;
  DECLARE outNotiX          BIGINT(20) DEFAULT 0;
  DECLARE outNotiY          BIGINT(20) DEFAULT 0;
  -- 
  SET bHasComment = 0;
  --
  IF pnCollectionId = 0 THEN
    -- 
    SELECT ca.old_collection_id, ca.object_type, ca.object_uid, st.omni_cal_id
      INTO nCollectionId, vObjectType, oldObjectUid, calendarUri
      FROM collection_activity ca
      JOIN setting AS st ON st.user_id = pnUserId
     WHERE ca.id = pnCollectionActivityId 
       AND ca.user_id = pnUserId;
    -- 
  ELSE
    -- 
    SELECT ca.old_collection_id, ca.object_type, ca.object_uid, co.calendar_uri
      INTO nCollectionId, vObjectType, oldObjectUid, calendarUri
      FROM collection_activity ca
      JOIN `collection` co ON (co.id = pnCollectionId AND co.user_id = pnUserId  AND co.is_trashed = 0)
     WHERE ca.id = pnCollectionActivityId 
       AND ca.user_id = pnUserId;
    -- 
  END IF;
  --
  IF ifnull(vObjectType, '') <> 'URL' THEN
    --
    SET vObjectHref = CONCAT('/calendarserver.php/calendars/', pvUserEmail, '/', calendarUri,'/',pvObjectUid,'.ics');
    --
  END IF;
  --

  IF (nCollectionId >= 0 AND nCollectionId <> pnCollectionId) THEN
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
           ,ca.object_href       = vObjectHref
           ,ca.updated_date      = nUpdatedDate
      WHERE ca.id      = pnCollectionActivityId 
        AND ca.user_id = pnUserId;
     -- CREATE notification 
     CALL c2024_createNotiWhenMove(outNotiX, outNotiY, outNotiYDate
                                  ,pnUserId, pvUserEmail, nCollectionId, pnCollectionId, oldObjectUid
                                  ,pvObjectUid, vObjectType, pvContent, pnActionTime, nUpdatedDate);
     --
     SELECT cn.content
       INTO vObjectTitle
       FROM collection_notification cn
      WHERE cn.id = nReturn;
     -- UPDATE ALL history, comment
     SET bHasComment = a2024_afterMoveCollectionActivity(pnCollectionActivityId, nUpdatedDate);
    --
  END IF;
  -- RETURN VALUES  
  SELECT bHasComment has_comment
        ,nCollectionId collection_id
        ,vObjectHref object_href
        ,vObjectTitle object_title
        ,nUpdatedDate max_updated_date
        ,vObjectType object_type
        ,outNotiX source_noti_id
        ,outNotiY dest_noti_id
        ,outNotiYDate updated_date
        ,CONVERT(oldObjectUid USING cp1251) object_uid_old
        ;
END