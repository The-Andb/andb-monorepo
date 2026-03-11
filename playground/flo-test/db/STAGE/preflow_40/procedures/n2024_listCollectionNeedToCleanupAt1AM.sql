CREATE PROCEDURE `n2024_listCollectionNeedToCleanupAt1AM`(pnLimit INT)
BEGIN
  --
  DECLARE nNOW_AT_1AM INT DEFAULT UNIX_TIMESTAMP(DATE_FORMAT(NOW(), '%Y-%m-%d 01:00:00'));
  --
  SET SESSION group_concat_max_len = 500000;
  --
  WITH user_remove_time AS (
   SELECT cnm.member_user_id AS user_id
         ,cnm.collection_id
         ,st2.notification_clean_date
         ,(nNOW_AT_1AM - st2.notification_clean_date) AS time_to_remove
     FROM collection_notification_member cnm
     JOIN setting st2 ON st2.user_id = cnm.member_user_id
    WHERE cnm.is_active = 1
      AND st2.notification_clean_date > 0
      )
  SELECT count(co.id) total
        ,upil.id upil_id
        ,uu.id user_id
        ,uu.email
        ,GROUP_CONCAT(co.id) collection_ids
    FROM `user` uu
    JOIN collection co ON (co.user_id = uu.id)
    LEFT JOIN user_process_invalid_link upil ON (uu.id = upil.user_id)
    JOIN user_remove_time urt ON urt.collection_id = co.id
    WHERE EXISTS (
                 SELECT 1
                  FROM collection_notification cn
                 WHERE cn.collection_id = co.id
                   AND cn.created_date < urt.time_to_remove
                 LIMIT 1
                )
     AND (upil.id IS NULL OR nNOW_AT_1AM - upil.notification_scanned_date >= 43200) -- 0.5 day
   GROUP BY uu.id
   ORDER BY 1 DESC
   LIMIT pnLimit;
  --
  SET SESSION group_concat_max_len = 1024;
  --
END