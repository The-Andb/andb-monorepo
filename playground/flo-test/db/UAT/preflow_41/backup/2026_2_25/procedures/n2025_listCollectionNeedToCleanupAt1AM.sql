CREATE PROCEDURE `n2025_listCollectionNeedToCleanupAt1AM`(pnLimit INT)
BEGIN
  DECLARE nNOW_AT_1AM INT DEFAULT UNIX_TIMESTAMP(DATE_FORMAT(NOW(), '%Y-%m-%d 01:00:00'));
  --
  SET SESSION group_concat_max_len = 500000;
  --
  -- Very simple query FROM summary TABLE
  SELECT COUNT(DISTINCT cncq.collection_id) AS total
        ,upil.id AS upil_id
        ,uu.id AS user_id
        ,uu.email
        ,GROUP_CONCAT(DISTINCT cncq.collection_id ORDER BY cncq.collection_id) AS collection_ids
    FROM collection_notification_cleanup cncq
    INNER JOIN `user` uu ON uu.id = cncq.user_id
    LEFT JOIN user_process_invalid_link upil ON uu.id = upil.user_id
   WHERE cncq.status = 0  -- pending
     AND cncq.time_to_remove < nNOW_AT_1AM
     AND cncq.total_outdated_count > 0
     -- AND (upil.id IS NULL OR nNOW_AT_1AM - upil.notification_scanned_date >= 21600) -- 0.5 day
   GROUP BY uu.id, upil.id
   ORDER BY total DESC
   LIMIT pnLimit;
  --
  SET SESSION group_concat_max_len = 1024;
  --
END