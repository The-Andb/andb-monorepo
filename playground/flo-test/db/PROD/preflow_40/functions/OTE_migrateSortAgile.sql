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
  DECLARE nOrderNumber     DECIMAL(20,10);
  DECLARE nCount           INT DEFAULT 0;
  DECLARE vObjectUid       VARBINARY(1000);
  DECLARE vObjectType      VARBINARY(50);
  DECLARE vCalendarUri     VARCHAR(255);
  DECLARE vEmail           VARCHAR(100);
  DECLARE agile_cursor CURSOR FOR
  # Start of: main script
  SELECT lco.object_uid, lco.object_type, co.user_id, co.id collection_id, co.calendar_uri, u.email
      ,so.order_number
     FROM linked_collection_object lco
     JOIN collection co ON (lco.collection_id = co.id)
     JOIN calendarinstances ci ON (ci.uri = co.calendar_uri)
     JOIN cal_todo ct ON (ct.uid = lco.object_uid 
                          AND ci.calendarid = ct.calendarid
                          AND ct.category > 0)
     JOIN user u ON u.id = co.user_id
LEFT JOIN sort_object so ON (so.user_id = co.user_id AND so.object_type = 'VTODO' AND so.object_uid = lco.object_uid)
LEFT JOIN sort_agile sa ON (lco.collection_id = sa.collection_id 
                          AND lco.object_uid = sa.object_uid 
                          AND lco.object_type = sa.object_type)
     WHERE sa.id IS NULL
    --   AND co.id = 8041103
     ;
     
   # END of: main script
   DECLARE CONTINUE handler FOR NOT found SET no_more_rows = TRUE;
   --
   OPEN agile_cursor;
   agile_loop: LOOP
     --
     FETCH agile_cursor 
      INTO vObjectUid, vObjectType, nUserId, nCollectionId, vCalendarUri, vEmail, nOrderNumber;
     --
     IF (no_more_rows) THEN
       CLOSE agile_cursor;
       LEAVE agile_loop;
     END IF;
     --
     SET nUpdatedDate = nUpdatedDate + nCount;
     
    
    -- GET min ORDER
    IF isnull(nOrderNumber) THEN
    --
    SELECT ifnull(min(sa.order_number), 0)
      INTO nMinSort
      FROM sort_agile sa
     WHERE sa.user_id = nUserId
       AND sa.collection_id = nCollectionId;
       --
       SET nOrderNumber = nMinSort - 0.01;
      --
    END IF;
    -- 
    INSERT INTO `sort_agile`
      (`collection_id`,`calendar_uri`,`user_id`,`account_id`, `object_uid`,`object_type`
       ,`object_href`,`order_number`
       ,`order_update_time`,`created_date`,`updated_date`)
    VALUES
      (nCollectionId, vCalendarUri, nUserId, 0, vObjectUid, vObjectType
      ,concat('/calendarserver.php/calendars/',vEmail,'/',vCalendarUri,'/',vObjectUid,'.ics')
      ,nOrderNumber, nUpdatedDate, nUpdatedDate, nUpdatedDate)
      ON DUPLICATE KEY UPDATE updated_date=VALUES(updated_date)+0.001;
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