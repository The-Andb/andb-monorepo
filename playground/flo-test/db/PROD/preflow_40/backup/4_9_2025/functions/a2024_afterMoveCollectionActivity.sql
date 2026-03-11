CREATE FUNCTION `a2024_afterMoveCollectionActivity`(
pnCollectionActivityId  BIGINT(20)
,pnUpdatedDate        DOUBLE(13,3)) RETURNS TINYINT(1)
BEGIN
  --
  DECLARE nUpdatedDate       DOUBLE(13,3) DEFAULT -1;
  DECLARE nID                BIGINT(20) DEFAULT -1;
  DECLARE nDateItemHistory   DOUBLE(13,3);
  DECLARE nDateItemComment   DOUBLE(13,3);
  DECLARE vTable             VARCHAR(255);
  DECLARE bHasComment        INT DEFAULT 0;
  -- 
  DECLARE no_more_rows     boolean;
  DECLARE activity_cursor CURSOR FOR
  --
  (
  SELECT ch.id, 'history' 
    FROM collection_history ch
   WHERE ch.collection_activity_id = pnCollectionActivityId 
   ORDER BY ch.updated_date DESC
  )
   UNION
  (
  SELECT cc.id, 'comment' 
    FROM collection_comment cc  
   WHERE cc.collection_activity_id = pnCollectionActivityId 
   ORDER BY cc.updated_date DESC
  );
  --
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET no_more_rows = TRUE;
  -- 
  SET bHasComment = 0;
  --
  SET nDateItemHistory = pnUpdatedDate;
  SET nDateItemComment = pnUpdatedDate;
  --
  OPEN activity_cursor;
  activity_loop: LOOP
  FETCH activity_cursor
    INTO nID, vTable;
    -- stop LOOP WHEN no_more_rows
    IF no_more_rows THEN
      CLOSE activity_cursor;
      LEAVE activity_loop;
    END IF;
    --
    IF vTable = 'history' THEN
      -- 
      UPDATE collection_history ch
         SET ch.updated_date = nDateItemHistory
            ,ch.created_date = CASE 
                                    WHEN ch.created_date = ch.updated_date THEN nDateItemHistory 
                                    ELSE ch.created_date 
                                END
        WHERE ch.id = nID;

      --
      SET nDateItemHistory = nDateItemHistory - 0.001;
      -- 
    ELSEIF vTable = 'comment' THEN
      -- 
      UPDATE collection_comment cc 
         SET cc.updated_date = nDateItemComment
             ,cc.created_date = CASE 
                                    WHEN cc.created_date = cc.updated_date THEN nDateItemHistory 
                                    ELSE cc.created_date 
                                END
       WHERE cc.id = nID;
      --
      SET nDateItemComment = nDateItemComment - 0.001;
      SET bHasComment = 1;
      -- 
    END IF;
    --
  END LOOP activity_loop;
  --
  RETURN bHasComment;
  --
END