CREATE FUNCTION `OTE_migrateSortAgile`() RETURNS INT
BEGIN
  --
  DECLARE no_more_rows     boolean;
  DECLARE nUserId          BIGINT(20);
  DECLARE nCollectionId    BIGINT(20);
  DECLARE nUpdatedDate     DOUBLE(13,3) DEFAULT unix_timestamp(NOW(3));
  DECLARE nID              BIGINT(20);
  DECLARE nReturn          BIGINT(20) DEFAULT 0;
  DECLARE nMinSort         DECIMAL(20,10);
  DECLARE nCount           INT DEFAULT 0;
  DECLARE vObjectUid       VARBINARY(1000);
  DECLARE vObjectType      VARBINARY(50);
  DECLARE vCalendarUri     VARCHAR(255);
  DECLARE vEmail           VARCHAR(100);
  DECLARE agile_cursor CURSOR FOR
  # Start of: main script
  SELECT lco.object_uid, lco.object_type, co.user_id, co.id collection_id, co.calendar_uri
         ,u.email
     FROM linked_collection_object lco
     JOIN collection co ON lco.collection_id = co.id
     JOIN user u ON u.id = co.user_id
     JOIN pt_raw.pt_migration_status pms ON co.id = pms.collection_id
LEFT JOIN sort_agile sa ON (lco.collection_id = sa.collection_id 
                          AND lco.object_uid = sa.object_uid 
                          AND lco.object_type = sa.object_type)
    WHERE pms.id IN (1033574,1171660,1177210,1215470,1481472,1654355,2119982,2322037,2350530,2438691)
      AND sa.id IS NULL;
     
   # END of: main script
   DECLARE CONTINUE handler FOR NOT found SET no_more_rows = TRUE;
   --
   OPEN agile_cursor;
   agile_loop: LOOP
     --
     FETCH agile_cursor 
      INTO vObjectUid, vObjectType, nUserId, nCollectionId, vCalendarUri, vEmail;
     --
     IF (no_more_rows) THEN
       CLOSE agile_cursor;
       LEAVE agile_loop;
     END IF;
     --
     SET nUpdatedDate = nUpdatedDate + nCount;
     -- CHECK IF exist
     SELECT ifnull(max(sa.id), 0)
       INTO nID
       FROM sort_agile sa
      WHERE sa.user_id = nUserId
        AND sa.collection_id = nCollectionId
        AND sa.object_uid = vObjectUid
        AND sa.object_type = vObjectType;
    --
    IF nID = 0 THEN
      -- GET min ORDER
      SELECT ifnull(min(sa.order_number), 0)
        INTO nMinSort
        FROM sort_agile sa
       WHERE sa.user_id = nUserId
         AND sa.collection_id = nCollectionId;
      -- 
      INSERT INTO `sort_agile`
        (`collection_id`,`calendar_uri`,`user_id`,`account_id`, `object_uid`,`object_type`
         ,`object_href`,`order_number`
         ,`order_update_time`,`created_date`,`updated_date`)
      VALUES
        (nCollectionId, vCalendarUri, nUserId, 0, vObjectUid, vObjectType
        ,concat('/calendarserver.php/calendars/',vEmail,'/',vCalendarUri,'/',vObjectUid,'.ics')
        ,nMinSort - 0.01, nUpdatedDate, nUpdatedDate, nUpdatedDate);
    --
  END IF;
  --
  SET nReturn = c2022_sendLastModifyShare('sort_agile', nCollectionId, nUpdatedDate);
  --
  SET nCount = nCount + 1;
  --
  END LOOP agile_loop;
  --
  RETURN nCount;
  --
END