CREATE PROCEDURE `n2025_listOfNotification4DeleteCollection`(
  pnCollectionID BIGINT(20)
, pnOffset       INT
, pnLimit        INT
)
n2025_listOfNotification4DeleteCollection: BEGIN
  -- Variables
  DECLARE nCollectionID BIGINT(20) DEFAULT IFNULL(pnCollectionID, 0);
  DECLARE nNOW_AT_1AM INT DEFAULT UNIX_TIMESTAMP(DATE_FORMAT(NOW(), '%Y-%m-%d 01:00:00'));
  DECLARE nLimit INT DEFAULT IFNULL(pnLimit, 100);
  DECLARE nOffset INT DEFAULT IFNULL(pnOffset, 0);
  IF nCollectionID = 0 THEN
    --
    LEAVE n2025_listOfNotification4DeleteCollection;
    --
  END IF;
  -- Main Query
  WITH user_remove_time AS (
    -- Owners
    SELECT co.user_id, co.id collection_id
      FROM user uu
      JOIN collection co ON uu.id = co.user_id
     WHERE co.id = nCollectionID
    UNION ALL
    -- Shared Members
    SELECT csm.member_user_id user_id, csm.collection_id
      FROM user uu
      JOIN collection_shared_member csm ON uu.id = csm.member_user_id
--      WHERE st.notification_clean_date > 0
--        AND csm.id = nCollectionID
     WHERE csm.collection_id = nCollectionID
  )
  -- SELECT Notifications for Removal
   SELECT cn.id, urt.user_id
     FROM user_remove_time urt
     JOIN collection_notification cn ON (cn.collection_id = urt.collection_id)
LEFT JOIN user_notification un ON (un.collection_notification_id = cn.id AND un.user_id = urt.user_id AND un.user_id = urt.user_id)
     JOIN collection col ON col.id = cn.collection_id
    WHERE col.type = 3 -- shared only
      AND un.deleted_date IS NULL
      -- AND cn.id = 1091682
      -- ORDER BY cn.id
    LIMIT nLimit
   OFFSET nOffset;
END