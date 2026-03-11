CREATE FUNCTION `OTE_patchCommentByActivity`(
  pnCollectionActivityId BIGINT(20),
  pvObjectHref           VARCHAR(500),
  pnCollectionId         BIGINT(20),
  pnUpdatedDate          DOUBLE(13,3)
) RETURNS INT
BEGIN
  --
  DECLARE nID           BIGINT(20);
  DECLARE nReturn       BIGINT(20) DEFAULT 0;
  DECLARE nCount              INT DEFAULT 0;
  DECLARE vTable        VARCHAR(255);
  DECLARE nOldUpdated   DOUBLE(13,3);
  DECLARE nOldCreated   DOUBLE(13,3);
  DECLARE nActionTime   DOUBLE(13,3);
  DECLARE nOffsetHis    DOUBLE DEFAULT 0.000;
  DECLARE nOffsetCmt    DOUBLE DEFAULT 0.000;
  DECLARE no_more_rows  BOOLEAN DEFAULT FALSE;
  DECLARE outHistoryDate DOUBLE(13,3) DEFAULT 0;
  DECLARE outCommentDate DOUBLE(13,3) DEFAULT 0;
  --
  DECLARE activity_cursor CURSOR FOR
     SELECT id, 'history' AS vTable, updated_date, created_date, action_time
      FROM collection_history
      WHERE collection_activity_id = pnCollectionActivityId
    UNION ALL
    SELECT id, 'comment' AS vTable, updated_date, created_date, action_time
      FROM collection_comment
     WHERE collection_activity_id = pnCollectionActivityId
     ORDER BY action_time ASC
    ;
  -- Handler for END of CURSOR
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET no_more_rows = TRUE;
  --
  OPEN activity_cursor;
  --
  activity_loop: LOOP
    FETCH activity_cursor INTO nID, vTable, nOldUpdated, nOldCreated, nActionTime;
    IF no_more_rows THEN
      CLOSE activity_cursor;
      LEAVE activity_loop;
    END IF;
    -- UPDATE history OR comment
    -- UPDATE history OR comment
    IF vTable = 'history' THEN
      UPDATE collection_history
         SET updated_date = pnUpdatedDate + nOffsetHis,
             created_date = pnUpdatedDate + nOffsetHis - IF(nOldUpdated - nOldCreated > 0, 0.001, 0),
             collection_id = pnCollectionId
       WHERE id = nID;
      -- Store the last history updated_date
      SET outHistoryDate = pnUpdatedDate + nOffsetHis;
      -- Increase offset BY 0.001 for EACH record
      SET nOffsetHis = nOffsetHis + 0.002;
      --
    ELSEIF vTable = 'comment' THEN
      UPDATE collection_comment
         SET updated_date = pnUpdatedDate + nOffsetCmt,
             created_date = pnUpdatedDate + nOffsetCmt - IF(nOldUpdated - nOldCreated > 0, 0.001, 0),
             collection_id = pnCollectionId
       WHERE id = nID;
      --
      -- Store the last comment updated_date
      SET outCommentDate = pnUpdatedDate + nOffsetCmt;
      -- Increase offset BY 0.001 for EACH record
      SET nOffsetCmt = nOffsetCmt + 0.002;
      --
    END IF;
    --
    SET nCount = nCount + 1;
    --
  END LOOP activity_loop;
  --
  IF outHistoryDate > 0 THEN
    --
    SET nReturn = c2022_sendLastModifyShare(
        'collection_history'
        ,pnCollectionId
        , outHistoryDate
    );
   --
 END IF;
  --
  IF outCommentDate > 0 THEN
    --
    SET nReturn = c2022_sendLastModifyShare(
        'collection_comment'
        ,pnCollectionId
        , outCommentDate
    );
    --
  END IF;
  -- UPDATE EACH record
  UPDATE collection_activity ca
     SET ca.collection_id = nCollectionID
        ,ca.object_href   = pvObjectHref
        ,updated_date     = nUpdatedDate
   WHERE ca.id = vCAID;
  --
  RETURN nCount;
  --
END