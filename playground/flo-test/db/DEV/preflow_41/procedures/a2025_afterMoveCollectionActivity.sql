CREATE PROCEDURE `a2025_afterMoveCollectionActivity`(
  OUT outHistoryDate DOUBLE(13,3),
  OUT outCommentDate DOUBLE(13,3),
  OUT outHasHistory TINYINT(1),
  OUT outHasComment TINYINT(1),
  collectionActivityId BIGINT(20),
  updatedDate DOUBLE(13,3)
)
BEGIN
  --
  DECLARE nID           BIGINT(20);
  DECLARE vTable        VARCHAR(255);
  DECLARE nOldUpdated   DOUBLE(13,3);
  DECLARE nOldCreated   DOUBLE(13,3);
  DECLARE nCollectionId BIGINT(20);
  DECLARE nOffsetHis    DOUBLE DEFAULT 0.000;
  DECLARE nOffsetCmt    DOUBLE DEFAULT 0.000;
  DECLARE no_more_rows  BOOLEAN DEFAULT FALSE;
  --
  DECLARE activity_cursor CURSOR FOR
    SELECT id, 'history' AS vTable, updated_date, created_date
      FROM collection_history
      WHERE collection_activity_id = collectionActivityId
    UNION ALL
    SELECT id, 'comment' AS vTable, updated_date, created_date
      FROM collection_comment
      WHERE collection_activity_id = collectionActivityId
    ORDER BY updated_date ASC;
  -- Handler for END of CURSOR
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET no_more_rows = TRUE;
  -- Initialize OUT parameters
  SET outHasHistory = 0;
  SET outHasComment = 0;
  SET outHistoryDate = 0;
  SET outCommentDate = 0;
  -- GET collection_id for this activity
  SELECT collection_id
    INTO nCollectionId
    FROM collection_activity
    WHERE id = collectionActivityId;
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
         SET updated_date = updatedDate + nOffsetHis,
             created_date = updatedDate + nOffsetHis - (nOldUpdated - nOldCreated),
             collection_id = nCollectionId
       WHERE id = nID;
      -- Store the last history updated_date
      SET outHistoryDate = updatedDate + nOffsetHis;
      -- Increase offset BY 0.001 for EACH record
      SET nOffsetHis = nOffsetHis + 0.001;
      --
      SET outHasHistory = 1;
      --
    ELSEIF vTable = 'comment' THEN
      UPDATE collection_comment
         SET updated_date = updatedDate + nOffsetCmt,
             created_date = updatedDate + nOffsetCmt - (nOldUpdated - nOldCreated),
             collection_id = nCollectionId
       WHERE id = nID;
      --
      -- Store the last comment updated_date
      SET outCommentDate = updatedDate + nOffsetCmt;
      -- Increase offset BY 0.001 for EACH record
      SET nOffsetCmt = nOffsetCmt + 0.001;
      --
      SET outHasComment = 1;
      --
    END IF;
    --
  END LOOP activity_loop;
  --
END