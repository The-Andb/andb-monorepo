CREATE PROCEDURE `OTE_2025_fixDuplicateSortAgileOrderNumbers`()
BEGIN
  --
  DECLARE no_more_rows            boolean DEFAULT FALSE;
  DECLARE nCollectionId           BIGINT(20);
  DECLARE nDuplicateCount         INT(11);
  DECLARE nFixedCollections       INT(11) DEFAULT 0;
  --
  DECLARE collection_cursor CURSOR for
  # Start of: find collections WITH duplicates
  SELECT collection_id
        ,COUNT(*) AS duplicate_count
    FROM (
          SELECT collection_id
                ,order_number
                ,COUNT(*) AS cnt
            FROM sort_agile
           GROUP BY collection_id, order_number
          HAVING cnt > 1
         ) duplicates
   GROUP BY collection_id;
  # END of: find collections WITH duplicates
  --
  DECLARE CONTINUE handler for NOT found SET no_more_rows = TRUE;
  --
  OPEN collection_cursor;
  --
  read_loop: LOOP
    --
    FETCH collection_cursor INTO nCollectionId, nDuplicateCount;
    --
    IF no_more_rows THEN
      CLOSE collection_cursor;
      LEAVE read_loop;
    END IF;
    --
    SET @row_num = 0;
    SET @current_order = NULL;
    --
    # Start of: UPDATE duplicates BY adding small increments
    UPDATE sort_agile sa
    INNER JOIN (
                SELECT id
                      ,order_number
                      ,@row_num := IF(@current_order = order_number, @row_num + 1, 0) AS row_within_group
                      ,@current_order := order_number
                  FROM sort_agile
                 WHERE collection_id = nCollectionId
                 ORDER BY order_number, id
               ) ranked ON sa.id = ranked.id
       SET sa.order_number = sa.order_number + (ranked.row_within_group * 0.0000000001)
     WHERE sa.collection_id = nCollectionId
       AND ranked.row_within_group > 0;
    # END of: UPDATE duplicates
    --
    SET nFixedCollections = nFixedCollections + 1;
    --
    SELECT CONCAT('Fixed collection_id: ', nCollectionId) AS Progress;
    --
  END LOOP read_loop;
  --
  IF nFixedCollections > 0 THEN
    SELECT CONCAT('SUCCESS: Fixed ', nFixedCollections, ' collections') AS Result;
  ELSE
    SELECT 'SUCCESS: No duplicates found' AS Result;
  END IF;
  --
END