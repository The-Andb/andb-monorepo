CREATE PROCEDURE `n2025_listOfNotificationByObject`(
  pvObjectUid         VARBINARY(250)
  ,pvObjectType       VARBINARY(50)
  ,pnCollectionId     BIGINT(20)
  ,pnAccountId        INT(20)
  ,pnUserId           BIGINT(20)
  ,pvUsername         VARCHAR(100)
  )
BEGIN
  --
   SELECT cn.id
     FROM collection_notification cn
LEFT JOIN user_notification un ON (un.collection_notification_id = cn.id AND un.user_id = pnUserId)
     JOIN collection co ON cn.collection_id = co.id
     JOIN user usr ON (co.user_id = usr.id)
    WHERE (ifnull(pnCollectionId, 0) = 0 OR co.id = pnCollectionId)
      AND (ifnull(pnAccountId, 0) = 0 OR cn.account_id = pnAccountId)
      AND co.user_id = pnUserId
      AND cn.channel_id = 0
      AND cn.object_type= pvObjectType
      AND cn.object_uid = pvObjectUid
      AND un.deleted_date IS NULL
UNION ALL
   SELECT cn.id
     FROM collection_notification cn
LEFT JOIN user_notification un ON (un.collection_notification_id = cn.id AND un.user_id = pnUserId)
     JOIN collection co ON cn.collection_id = co.id
     JOIN user usr ON (co.user_id = usr.id)
     JOIN collection_shared_member csm ON (csm.collection_id = co.id AND csm.shared_status = 1)
    WHERE (ifnull(pnCollectionId, 0) = 0 OR co.id = pnCollectionId)
      AND (ifnull(pnAccountId, 0) = 0 OR cn.account_id = pnAccountId)
      AND ifnull(co.is_trashed, 0) = 0
      AND csm.member_user_id = pnUserId
      AND cn.object_type <> 'CHAT'
      AND co.type = 3 -- share only
      AND cn.object_type= pvObjectType
      AND cn.object_uid = pvObjectUid
      AND un.deleted_date IS NULL
UNION ALL
   SELECT cn.id
     FROM collection_notification cn 
LEFT JOIN user_notification un ON (un.collection_notification_id = cn.id AND un.user_id = pnUserId)
     JOIN conference_member cm ON (cn.channel_id = cm.channel_id)
     JOIN conference_channel cc ON (cc.id = cm.channel_id)
     JOIN `user` u ON (u.id = cm.user_id)
     JOIN realtime_channel rc ON (rc.type = 'CONFERENCE' AND cc.id = rc.internal_channel_id)
     JOIN realtime_channel_member rcm ON (rc.id = rcm.channel_id AND rcm.email = u.email)
     JOIN realtime_chat_channel_user_last_seen rculs ON (rculs.channel_id = rc.id AND rculs.email = u.email)
    WHERE cm.user_id = pnUserId
      AND cc.is_trashed = 0
      AND cm.revoke_time = 0
      AND cn.created_date >= cm.join_time
      AND cn.object_type = pvObjectType
      AND cn.object_uid = pvObjectUid
      AND un.deleted_date IS NULL
UNION ALL
   SELECT cn.id
     FROM collection_notification cn
LEFT JOIN user_notification un ON (un.collection_notification_id = cn.id AND un.user_id = pnUserId)
    WHERE cn.user_id = pnUserId
      AND cn.collection_id = 0
      AND cn.channel_id = 0
      AND (isnull(pvObjectType) OR find_in_set(cn.object_type, pvObjectType))
      AND un.deleted_date IS NULL;
  --
END