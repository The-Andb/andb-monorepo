CREATE PROCEDURE `OTE_patchLinkedCollectionObjectViaCalendar`(
    IN pnCollectionIds JSON
)
BEGIN
  --
  DECLARE no_more_rows        BOOLEAN DEFAULT FALSE;
  DECLARE nCount              INT DEFAULT 0;
  DECLARE nReturn             BIGINT DEFAULT 0;
  DECLARE nCollectionID       INT DEFAULT 0;
  DECLARE nCAID               INT DEFAULT 0;
  DECLARE nCalendarID         INT DEFAULT 0;
  DECLARE nOwnerUserId        BIGINT(20) DEFAULT 0;
  DECLARE vOwnerEmail         VARCHAR(255);
  DECLARE vCalendarUri        VARCHAR(255);
  DECLARE vObjectUid          VARBINARY(1000);
  DECLARE vObjectHref         VARCHAR(500);
  DECLARE vObjectType         VARBINARY(50) DEFAULT "VTODO";
  DECLARE nAccountId          INT DEFAULT 0;
  DECLARE nIsTrashed          TINYINT(1) DEFAULT 0;
  DECLARE nUpdatedDate        DOUBLE(13, 3) DEFAULT UNIX_TIMESTAMP(NOW(3));
  DECLARE nBasedDate          DOUBLE(13, 3) DEFAULT UNIX_TIMESTAMP(NOW(3));
  DECLARE nPrevCollectionID INT DEFAULT NULL;

  DECLARE ms_cursor CURSOR FOR
    WITH collection_ids_list AS (
        SELECT CAST(jt.val AS UNSIGNED) AS id
          FROM JSON_TABLE(CASE
                            WHEN pnCollectionIds IS NULL THEN '[]'
                            ELSE pnCollectionIds
                          END, '$[*]' COLUMNS(
                            val VARCHAR(255) PATH '$'
                        )
        ) jt
    )
    SELECT co.id AS collection_id
          ,co.user_id AS owner_user_id
          ,u.email AS owner_email
          ,co.calendar_uri
          ,ci.calendarid
          ,CONVERT(calo.uid USING cp1251)
          ,CONVERT(calo.componenttype USING cp1251)
      FROM collection_ids_list cil 
      JOIN collection co ON (co.id = cil.id)
      JOIN user u ON (u.id = co.user_id)
      JOIN calendarinstances ci ON (ci.uri = co.calendar_uri AND ci.principaluri = CONCAT('principals/', u.email))
      JOIN calendarobjects calo ON (calo.calendarid = ci.calendarid)
 LEFT JOIN linked_collection_object lco ON (lco.collection_id = co.id AND lco.object_uid = calo.uid)
     WHERE lco.id IS NULL
     AND calo.uid IS NOT NULL
     ORDER BY co.id, calo.id;
  --
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET no_more_rows = TRUE;
  --
  OPEN ms_cursor;
  --
  ms_loop: LOOP
    --
      FETCH ms_cursor 
       INTO nCollectionID, nOwnerUserId
           ,vOwnerEmail, vCalendarUri, nCalendarID, vObjectUid, vObjectType;
      --
      IF no_more_rows THEN 
        --
        IF nPrevCollectionID IS NOT NULL THEN
          --
          SET nReturn = c2022_sendLastModifyShare(
              'linked_collection_object'
             ,nPrevCollectionID
             ,nUpdatedDate
          );
          --
        END IF;

        CLOSE ms_cursor; 
        LEAVE ms_loop; 
      END IF;
      -- detect collection boundary
      IF nPrevCollectionID IS NOT NULL
         AND nCollectionID <> nPrevCollectionID THEN
        --
        SET nReturn = c2022_sendLastModifyShare(
            'linked_collection_object'
            ,nPrevCollectionID
            ,nUpdatedDate
        );
        --
      END IF;
      --
      SET nUpdatedDate = nBasedDate + nCount / 1000;
      SET vObjectHref = CONCAT('/calendarserver.php/calendars/', vOwnerEmail, '/', vCalendarUri, '/', vObjectUid, '.ics');
      --
      INSERT INTO linked_collection_object
        (user_id, collection_id, object_uid, object_type, account_id
        ,object_href, email_time, is_trashed, created_date, updated_date)
      VALUES
        (nOwnerUserId, nCollectionID, vObjectUid, vObjectType, nAccountId
        ,vObjectHref, 0, nIsTrashed, nUpdatedDate, nUpdatedDate)
       AS new ON DUPLICATE KEY UPDATE
               is_trashed   = new.is_trashed
              ,updated_date = new.updated_date
              ,email_time   = new.email_time
        ;
      --
      -- SELECT 'Finding collection_activity:' debug, nCollectionID, vObjectUid, vObjectType, nOwnerUserId;
      --
      BEGIN
        DECLARE done INT DEFAULT FALSE;
        DECLARE vCAID BIGINT;
        
        -- CURSOR TO GET ALL matching records
        DECLARE cur CURSOR FOR 
          SELECT ca.id
            FROM collection_activity ca
           WHERE ca.collection_id = 0
             AND ca.old_collection_id = nCollectionID
             AND ca.object_uid = vObjectUid
             AND ca.object_type = vObjectType
             AND ca.user_id = nOwnerUserId
            UNION DISTINCT
           SELECT ca.id
             FROM collection_comment cc
             JOIN collection_activity ca
               ON ca.id = cc.collection_activity_id
            WHERE cc.collection_id = nCollectionID
              AND ca.object_uid = vObjectUid
              AND ca.object_type = vObjectType
              AND ca.user_id = nOwnerUserId
            ORDER BY id DESC;
        
        DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

        OPEN cur;
        
        read_loop: LOOP
          FETCH cur INTO vCAID;
          
          IF done THEN
            LEAVE read_loop;
          END IF;
          -- Patch comment for EACH activity
          SET nReturn = OTE_patchCommentByActivity(vCAID, vObjectHref, nCollectionID, nUpdatedDate);
          
        END LOOP;
        
        CLOSE cur;
      END;
      SET nPrevCollectionID = nCollectionID;
      --
      SET nCount = nCount + 1;
    --
  END LOOP ms_loop;
  --
  SELECT nCount AS total_patched, nUpdatedDate AS last_modified;
  --
END