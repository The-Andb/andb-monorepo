CREATE PROCEDURE `n2023_listOfNotificationOutdated`(
  pnCollectionID BIGINT(20)
, pnOffset       INT
, pnLimit        INT
)
n2023_listOfNotificationOutdated: BEGIN
  -- Variables
  DECLARE nCollectionID BIGINT(20) DEFAULT IFNULL(pnCollectionID, 0);
  DECLARE nNOW_AT_1AM INT DEFAULT UNIX_TIMESTAMP(DATE_FORMAT(NOW(), '%Y-%m-%d 01:00:00'));
  DECLARE nPASSED_90D INT DEFAULT UNIX_TIMESTAMP(DATE_FORMAT(NOW() - INTERVAL 90 DAY, '%Y-%m-%d 01:00:00'));
  DECLARE nLimit INT DEFAULT IFNULL(pnLimit, 100);
  DECLARE nOffset INT DEFAULT IFNULL(pnOffset, 0);
  IF nCollectionID = 0 THEN
    --
    LEAVE n2023_listOfNotificationOutdated;
    --
  END IF;
  -- Main Query
  WITH user_remove_time AS (
   SELECT cnm.member_user_id AS user_id
         ,cnm.collection_id
         ,st.notification_clean_date
         ,(nNOW_AT_1AM - st.notification_clean_date) AS time_to_remove
     FROM collection_notification_member cnm
     JOIN setting st ON st.user_id = cnm.member_user_id
    WHERE cnm.collection_id = nCollectionID
      AND cnm.is_active = 1
      AND st.notification_clean_date > 0
),
-- pre-filter user_notifications IN ORDER TO OPTIMIZE perf
user_notifications_filtered AS (
  SELECT un.collection_notification_id, un.user_id
    FROM user_notification un
    JOIN user_remove_time urt ON un.user_id = urt.user_id
   WHERE deleted_date IS NULL
     AND un.created_date > nPASSED_90D
)
SELECT cn.id, urt.user_id
  FROM collection_notification cn
  JOIN user_remove_time urt ON (cn.collection_id = urt.collection_id AND cn.created_date < urt.time_to_remove)
  LEFT JOIN user_notifications_filtered un ON (un.collection_notification_id = cn.id AND un.user_id = urt.user_id)
  JOIN collection col ON col.id = cn.collection_id
 WHERE col.type = 3
   AND col.id = nCollectionID
   AND un.collection_notification_id IS NOT NULL
 LIMIT nLimit
OFFSET nOffset;
END