CREATE FUNCTION `c2022_createCollectionActivity`(pnCollectionId         BIGINT(20)
                                                               ,pvObjectUid            VARBINARY(1000)
                                                               ,pvObjectType           VARBINARY(50)
                                                               ,pnCreatedDate          DOUBLE(13,3)
                                                               ,pnUpdatedDate          DOUBLE(13,3)) RETURNS BIGINT
BEGIN
  --
  -- CREATE collection activity BY collectionId
  --
  DECLARE nCAID         BIGINT(20);
  DECLARE nUserId       BIGINT(20);
  DECLARE vCalendarUri  VARCHAR(255);
  DECLARE vOwnerEmail   VARCHAR(255);
  DECLARE vObjectHref   TEXT DEFAULT '';
  DECLARE nCategoty     TINYINT(1) DEFAULT 0;
  --
  --
  SELECT ifnull(max(ca.id), 0)
    INTO nCAID
    FROM collection_activity ca
   WHERE ca.collection_id = pnCollectionId
     AND ca.object_uid = pvObjectUid;
  --
  IF ifnull(nCAID, 0) > 0 THEN
    --
    RETURN nCAID;
    --
  ELSE
    --
    SELECT u.email, co.calendar_uri, co.user_id
    INTO vOwnerEmail, vCalendarUri, nUserId
    FROM  collection co
    JOIN user u ON (u.id = co.user_id)
   WHERE co.id = pnCollectionId;
    -- find category
    IF pvObjectType = 'VTODO' THEN
      --
      SELECT ifnull(ct.category, 0)
        INTO nCategoty
        FROM cal_todo ct
       WHERE ct.uid = pvObjectUid
       ORDER BY id DESC
       LIMIT 1;
      --
    END IF;
    --
    IF ifnull(pvObjectType, '') NOT IN('KANBAN' ,'URL') THEN
      --
      SET vObjectHref = concat("/calendarserver.php/calendars/", vOwnerEmail, "/", vCalendarUri, "/", pvObjectUid, ".ics");
      --
    END IF;
    --
    INSERT INTO `collection_activity`
     (`collection_id`, old_collection_id, user_id, `object_uid`, `object_type`, object_href, category, `created_date`, `updated_date`)
    VALUES
     (pnCollectionId, pnCollectionId, nUserId, pvObjectUid, pvObjectType, vObjectHref, nCategoty, pnCreatedDate, pnUpdatedDate);
    --
    SELECT last_insert_id()
      INTO nCAID;
    --
  END IF;
  --
  RETURN nCAID;
  --
END