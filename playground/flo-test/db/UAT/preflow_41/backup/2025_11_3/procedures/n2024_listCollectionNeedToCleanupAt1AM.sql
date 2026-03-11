CREATE PROCEDURE `n2024_listCollectionNeedToCleanupAt1AM`(pnLimit INT)
BEGIN
  --
  DECLARE nNOW_AT_1AM INT DEFAULT UNIX_TIMESTAMP(DATE_FORMAT(NOW(), '%Y-%m-%d 01:00:00'));
  --
  SET SESSION group_concat_max_len = 500000;
  --
  SELECT count(co.id) total
        ,upil.id upil_id
        ,uu.id user_id
        ,uu.email
        ,GROUP_CONCAT(co.id) collection_ids
    FROM `user` uu 
    JOIN setting st ON (st.user_id = uu.id)
    JOIN collection co ON (co.user_id = uu.id)
    LEFT JOIN user_process_invalid_link upil ON (uu.id = upil.user_id)
   WHERE EXISTS (
         SELECT 1
           FROM collection_notification cn
          WHERE cn.collection_id = co.id
            AND EXISTS (
               SELECT 1
                 FROM (
                SELECT s2.notification_clean_date
                  FROM setting s2
                 WHERE s2.user_id = co.user_id
                   AND s2.notification_clean_date > 0
                   AND cn.created_date < (nNOW_AT_1AM - st.notification_clean_date)
                 UNION
                SELECT s2.notification_clean_date
                  FROM collection_shared_member csm
                  JOIN setting s2 ON (s2.user_id = csm.member_user_id)
                 WHERE csm.collection_id = co.id
                   AND s2.notification_clean_date > 0
                   AND cn.created_date < (nNOW_AT_1AM - st.notification_clean_date)
                    ) all_settings
        )
    )
     AND (upil.id IS NULL OR nNOW_AT_1AM - upil.notification_scanned_date >= 86400)
   GROUP BY uu.id
   ORDER BY 1 DESC
   LIMIT pnLimit
      ;
  --
  SET SESSION group_concat_max_len = 1024;
  --
END