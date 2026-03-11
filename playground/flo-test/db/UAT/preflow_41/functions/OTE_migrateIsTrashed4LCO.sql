CREATE FUNCTION `OTE_migrateIsTrashed4LCO`(pnCollectionId BIGINT) RETURNS INT
BEGIN
    DECLARE no_more_rows        boolean;
    DECLARE nCount              INT DEFAULT 0;
    DECLARE nReturn             INT DEFAULT 0;
    DECLARE nID                 BIGINT(20);
    DECLARE nUserID             BIGINT(20);
    DECLARE nCollectionID       BIGINT(20);
    DECLARE nUpdatedDate        DOUBLE(13,3);
    DECLARE nOldUpdatedDate     DOUBLE(13,3);
    DECLARE nOldCollectionId    BIGINT(20) DEFAULT NULL;
    --
    DECLARE lco_cursor CURSOR FOR
    # Start of: main script;
    WITH base_time AS (
      SELECT UNIX_TIMESTAMP(NOW(3)) AS base_sec
    )
    SELECT lco.id, lco.collection_id
          ,lco.user_id
          ,ROUND(bt.base_sec + (row_number() over (ORDER BY id) - 1) * 0.001, 3) updated_date
      FROM trash_collection tc
      JOIN linked_collection_object lco ON (tc.user_id = lco.user_id
                                          AND tc.object_type = 'VTODO'
                                          AND tc.object_uid = lco.object_uid
                                          AND tc.object_type = lco.object_type
                                          AND tc.object_href = lco.object_href)
        CROSS JOIN base_time bt
        WHERE lco.is_trashed <> 1
          AND (pnCollectionId IS NULL OR lco.collection_id = pnCollectionId)
        ORDER BY lco.collection_id;
    # END of: main script
   DECLARE CONTINUE handler FOR NOT found SET no_more_rows = TRUE;
   --
   OPEN lco_cursor;
   lco_loop: LOOP
     -- start LOOP lco_cursor
     FETCH lco_cursor INTO nID, nCollectionID, nUserID, nUpdatedDate;
     -- stop LOOP WHEN no_more_rows
     IF (no_more_rows) THEN
       -- send last modify for the last collection
      IF nOldCollectionId IS NOT NULL THEN
          SET nReturn = c2022_sendLastModifyShare('linked_collection_object', nOldCollectionId, nOldUpdatedDate);
      END IF;
       CLOSE lco_cursor;
       LEAVE lco_loop;
       --
     END IF;
     # main UPDATE
     UPDATE linked_collection_object lco
        SET lco.is_trashed = 1
           ,lco.updated_date = nUpdatedDate
      WHERE lco.id = nID
        AND lco.user_id = nUserID;
        
     -- send last modified at last item
      IF nOldCollectionId IS NULL THEN
          SET nOldCollectionId = nCollectionId;
          SET nOldUpdatedDate = nUpdatedDate;
      END IF;

      IF nCollectionId <> nOldCollectionId THEN
        --
        SET nReturn = c2022_sendLastModifyShare('linked_collection_object', nOldCollectionId, nOldUpdatedDate);
        SET nOldCollectionId = nCollectionId;
        SET nOldUpdatedDate = nUpdatedDate;
        --
      END IF;
     
     --
     SET nCount = nCount + 1;
     # main UPDATE
   END LOOP lco_loop;
   --
RETURN nCount;
END