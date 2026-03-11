CREATE FUNCTION `a2024_afterMoveCollectionActivity`(
  pnCollectionActivityId BIGINT(20),
  pnUpdatedDate DOUBLE(13,3)
) RETURNS TINYINT(1)
BEGIN
  --
  DECLARE nID           BIGINT(20);
  DECLARE vTable        VARCHAR(255);
  DECLARE nOldUpdated   DOUBLE(13,3);
  DECLARE nOldCreated   DOUBLE(13,3);
  DECLARE nCollectionId BIGINT(20);
  DECLARE bHasComment   TINYINT(1) DEFAULT 0;
  DECLARE nOffsetHis    DOUBLE DEFAULT 0.000;
  DECLARE nOffsetCmt    DOUBLE DEFAULT 0.000;
  DECLARE no_more_rows  BOOLEAN DEFAULT FALSE;
  --
  DECLARE activity_cursor CURSOR FOR
    SELECT id, 'history' AS vTable, updated_date, created_date
      FROM collection_history
      WHERE collection_activity_id = pnCollectionActivityId
    UNION ALL
    SELECT id, 'comment' AS vTable, updated_date, created_date
      FROM collection_comment
      WHERE collection_activity_id = pnCollectionActivityId
    ORDER BY updated_date ASC;
  -- Handler for END of CURSOR
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET no_more_rows = TRUE;
  -- GET collection_id for this activity
  SELECT collection_id
    INTO nCollectionId
    FROM collection_activity
    WHERE id = pnCollectionActivityId;
  --
  OPEN activity_cursor;
  --
  activity_loop: LOOP
    FETCH activity_cursor INTO nID, vTable, nOldUpdated, nOldCreated;
    IF no_more_rows THEN
      CLOSE activity_cursor;
      LEAVE activity_loop;
    END IF;
    -- UPDATE history OR comment
    IF vTable = 'history' THEN
      UPDATE collection_history
         SET updated_date = pnUpdatedDate + nOffsetHis,
             created_date = pnUpdatedDate + nOffsetHis - (nOldUpdated - nOldCreated),
             collection_id = nCollectionId
       WHERE id = nID;
      -- Increase offset BY 0.001 for EACH record
      SET nOffsetHis = nOffsetHis + 0.001;
      --
    ELSEIF vTable = 'comment' THEN
      UPDATE collection_comment
         SET updated_date = pnUpdatedDate + nOffsetCmt,
             created_date = pnUpdatedDate + nOffsetCmt - (nOldUpdated - nOldCreated),
             collection_id = nCollectionId
       WHERE id = nID;
      --
      -- Increase offset BY 0.001 for EACH record
      SET nOffsetCmt = nOffsetCmt + 0.001;
      --
      SET bHasComment = 1;
      --
    END IF;
    --
  END LOOP activity_loop;
  --
  RETURN bHasComment;
  --
END