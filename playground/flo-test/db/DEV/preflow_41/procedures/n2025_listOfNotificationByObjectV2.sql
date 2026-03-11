CREATE PROCEDURE `n2025_listOfNotificationByObjectV2`(
  pvObjectUid         VARBINARY(250)
  ,pvObjectType       VARBINARY(50)
  ,pnCollectionId     BIGINT(20)
  ,pnAccountId        INT(20)
  ,pnUserId           BIGINT(20)
  ,pvUsername         VARCHAR(100)
  ,pnStatus           TINYINT(1)
  )
BEGIN
  --
  SELECT cn.id
    FROM user_notification un
    JOIN collection_notification cn ON (un.collection_notification_id = cn.id)
    JOIN collection_notification_member cnm ON (un.user_id = cnm.member_user_id AND (cn.collection_id = cnm.collection_id AND cn.channel_id = cnm.channel_id))
   WHERE un.user_id      = pnUserId
     AND (ifnull(pnCollectionId, 0) = 0 OR cn.collection_id = pnCollectionId)
     AND (ifnull(pnAccountId, 0) = 0 OR cn.account_id = pnAccountId)
     AND cn.object_type  = pvObjectType
     AND cn.object_uid   = pvObjectUid
     AND un.is_active    = 1
     AND (
          un.status = 0
           OR un.status NOT IN (pnStatus, 2)
        );
  --
END