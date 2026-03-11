CREATE PROCEDURE `n2025_listOfNotificationOutdated`(
  pvCollectionIds JSON,
  pnOffset        INT,
  pnLimit         INT
)
BEGIN
  DECLARE nNOW_AT_1AM INT DEFAULT UNIX_TIMESTAMP(DATE_FORMAT(NOW(), '%Y-%m-%d 01:00:00'));
  DECLARE nPASSED_90D INT DEFAULT UNIX_TIMESTAMP(DATE_FORMAT(NOW() - INTERVAL 90 DAY, '%Y-%m-%d 01:00:00'));
  DECLARE nLimit  INT DEFAULT IFNULL(pnLimit, 100);
  DECLARE nOffset INT DEFAULT IFNULL(pnOffset, 0);

WITH collection_ids_list AS (
     SELECT CAST(jt.val AS UNSIGNED) AS id
       FROM JSON_TABLE(
              COALESCE(pvCollectionIds, '[]'),
              '$[*]' COLUMNS(val VARCHAR(255) PATH '$')
            ) jt
  ),
  user_remove_time AS (
     SELECT cnm.member_user_id AS user_id,
            cnm.collection_id,
            st.notification_clean_date,
            (nNOW_AT_1AM - st.notification_clean_date) AS time_to_remove
       FROM collection_notification_member cnm
       JOIN setting st ON st.user_id = cnm.member_user_id
       JOIN collection_ids_list cid ON cid.id = cnm.collection_id
      WHERE cnm.is_active = 1
        AND st.notification_clean_date > 0
  ),
  user_notifications_filtered AS (
     SELECT un.collection_notification_id,
            un.user_id
       FROM user_notification un
       JOIN user_remove_time urt USING (user_id)
      WHERE un.deleted_date IS NULL
        AND un.created_date > nPASSED_90D
  )
  SELECT cn.id,
         urt.user_id
    FROM user_remove_time urt
    JOIN collection_notification cn
      ON cn.collection_id = urt.collection_id
     AND cn.created_date < urt.time_to_remove
    JOIN collection col
      ON col.id = cn.collection_id
     AND col.type = 3
    JOIN user_notifications_filtered un
      ON un.collection_notification_id = cn.id
     AND un.user_id = urt.user_id
    JOIN collection_ids_list cid
      ON cid.id = cn.collection_id
   LIMIT nLimit
  OFFSET nOffset;
END