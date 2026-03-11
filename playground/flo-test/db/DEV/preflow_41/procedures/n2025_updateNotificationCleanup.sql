CREATE PROCEDURE `n2025_updateNotificationCleanup`()
BEGIN
  DECLARE nNOW_AT_1AM INT DEFAULT UNIX_TIMESTAMP(DATE_FORMAT(NOW(), '%Y-%m-%d 01:00:00'));
  DECLARE vRowsAffected INT DEFAULT 0;
  DECLARE vDeletedCollections INT DEFAULT 0;
  DECLARE vDeletedMembers INT DEFAULT 0;
  -- STEP 1: Cleanup deleted collections
  DELETE cnc FROM collection_notification_cleanup cnc
   WHERE EXISTS (
     SELECT 1 
     FROM collection co 
     WHERE co.id = cnc.collection_id
       AND co.is_trashed = 2
   );
  SET vDeletedCollections = ROW_COUNT();
  
  -- STEP 2: Cleanup inactive members
  DELETE cnc FROM collection_notification_cleanup cnc
   LEFT JOIN collection_notification_member cnm 
     ON cnm.collection_id = cnc.collection_id
    AND cnm.member_user_id = cnc.member_user_id
    AND cnm.is_active = 1
   WHERE cnm.id IS NULL;
  SET vDeletedMembers = ROW_COUNT();
  
  -- STEP 3: INSERT/UPDATE ALL collection-member pairs that have outdated notifications
  -- Matches original query logic exactly:
  -- - Original query uses EXISTS which only includes pairs WITH outdated notifications
  -- - Processes ALL pairs (no batching TO avoid missing data)
  -- - No time window filter (checks ALL notifications)
  INSERT INTO collection_notification_cleanup 
    (user_id, collection_id, member_user_id, time_to_remove, 
     oldest_notification_date, total_outdated_count, 
     last_checked_date, created_date, updated_date, status)
  SELECT co.user_id AS user_id
        ,urt.collection_id
        ,urt.user_id AS member_user_id
        ,urt.time_to_remove
        ,MIN(cn.created_date) AS oldest_notification_date
        ,COUNT(cn.id) AS total_outdated_count
        ,nNOW_AT_1AM AS last_checked_date
        ,UNIX_TIMESTAMP() AS created_date
        ,UNIX_TIMESTAMP() AS updated_date
        ,0 AS status  -- pending (only pairs WITH outdated notifications are inserted)
    FROM (
      -- GET ALL collection-member pairs WITH settings (matches original user_remove_time CTE)
      SELECT cnm.member_user_id AS user_id
            ,cnm.collection_id
            ,(nNOW_AT_1AM - st2.notification_clean_date) AS time_to_remove
        FROM collection_notification_member cnm
        INNER JOIN setting st2 ON st2.user_id = cnm.member_user_id
       WHERE cnm.is_active = 1
         AND st2.notification_clean_date > 0
    ) urt
    INNER JOIN collection co ON co.id = urt.collection_id
     AND co.is_trashed = 0
    INNER JOIN collection_notification cn 
      ON cn.collection_id = urt.collection_id
     AND cn.created_date < urt.time_to_remove
     -- Note: INNER JOIN matches original EXISTS logic - only includes pairs WITH outdated notifications
     -- No time window filter TO MATCH original query (checks ALL notifications)
   GROUP BY co.user_id, urt.collection_id, urt.user_id, urt.time_to_remove
  ON DUPLICATE KEY UPDATE
    time_to_remove = VALUES(time_to_remove),
    oldest_notification_date = VALUES(oldest_notification_date),
    total_outdated_count = VALUES(total_outdated_count),
    last_checked_date = VALUES(last_checked_date),
    updated_date = UNIX_TIMESTAMP(),  -- USE current timestamp for updates
    status = 0;  -- Always SET TO pending since we only INSERT pairs WITH outdated notifications
  
  SET vRowsAffected = ROW_COUNT();
  
  -- STEP 4: Mark completed
  UPDATE collection_notification_cleanup
     SET status = 2, updated_date = UNIX_TIMESTAMP()
   WHERE status = 0
     AND time_to_remove < nNOW_AT_1AM
     AND total_outdated_count = 0;
  
  -- STEP 5: Cleanup old completed records ONLY IF collection/member no longer EXISTS
  -- NOTE: Same logic AS main PROCEDURE - we don't DELETE just because records are old.
  --       Deletion of obsolete records IS already handled IN STEP 1 & 2.
  
  SELECT vRowsAffected AS rows_inserted_updated,
         vDeletedCollections AS rows_deleted_collections,
         vDeletedMembers AS rows_deleted_members;
END