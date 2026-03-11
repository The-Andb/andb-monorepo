CREATE PROCEDURE `OTE_fixDuplicateSortAgileOrderNumbers`()
BEGIN
  --
  DECLARE no_more_rows            boolean DEFAULT FALSE;
  DECLARE nCollectionId           BIGINT(20);
  DECLARE nDuplicateCount         INT(11);
  DECLARE nFixedCollections       INT(11) DEFAULT 0;
  DECLARE dLastModifiedTime       DOUBLE(13,3);
  --
  DECLARE collection_cursor CURSOR for
  # Start of: find collections WITH duplicates
  SELECT collection_id
        ,COUNT(*) AS duplicate_count
    FROM (
          SELECT collection_id
                ,order_number
                ,COUNT(*) AS cnt
            FROM preflow_41.sort_agile
           GROUP BY collection_id, order_number
          HAVING COUNT(*) > 1
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
    SET dLastModifiedTime = UNIX_TIMESTAMP(NOW(3));
    --
    # Start of: UPDATE duplicates BY adding small increments
    UPDATE preflow_41.sort_agile sa
    INNER JOIN (
                SELECT id
                      ,order_number
                      ,@row_num := IF(@current_order = order_number, @row_num + 1, 0) AS row_within_group
                      ,@current_order := order_number
                  FROM preflow_41.sort_agile
                 WHERE collection_id = nCollectionId
                 ORDER BY order_number, id
               ) ranked ON sa.id = ranked.id
       SET sa.order_number = sa.order_number + (ranked.row_within_group * 0.0000000001)
          ,sa.order_update_time = dLastModifiedTime
          ,sa.updated_date = dLastModifiedTime
     WHERE sa.collection_id = nCollectionId
       AND ranked.row_within_group > 0;
    # END of: UPDATE duplicates
    --
    # Start of: UPDATE api last modified for collection members
    --
    UPDATE preflow_41.api_last_modified alm
     INNER JOIN preflow_41.collection_notification_member cnm
        ON cnm.member_user_id = alm.user_id
       SET alm.api_modified_date = dLastModifiedTime
          ,alm.updated_date = dLastModifiedTime
     WHERE cnm.collection_id = nCollectionId
       AND cnm.is_active = 1
       AND alm.api_name = 'agile_order';
    --
    UPDATE preflow_41.collection_shared_last_modified cslm
       SET cslm.updated_date = dLastModifiedTime
     WHERE cslm.collection_id = nCollectionId
       AND cslm.object_type = 'agile_order';
    # END of: UPDATE api last modified
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