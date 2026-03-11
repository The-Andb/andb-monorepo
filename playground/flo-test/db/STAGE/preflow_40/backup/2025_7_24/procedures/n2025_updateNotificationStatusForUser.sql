CREATE PROCEDURE `n2025_updateNotificationStatusForUser`(pnPermission     TINYINT(1)
                              ,pnCollectionID   BIGINT(20)
                              ,pnNotiID         BIGINT(20)
                              ,pnStatus         TINYINT(2) --   UNREAD = 0  READ = 1  CLOSED = 2
                              ,pdActionTime     DOUBLE(13,3)
                              ,pnUpdatedDate    DOUBLE(13,3)
                              ,pnUserID         BIGINT(20)
                              ,pvEmail          VARCHAR(100)
                              )
n2023_updateNotificationStatusForUser:BEGIN
  --
  DECLARE nID               INT(11);
  DECLARE nReturn           INT(11);
  DECLARE isOwner           boolean;
  DECLARE isNotiOwner       boolean;
  DECLARE isMember          boolean;
  DECLARE isTrash           TINYINT(1) DEFAULT 0;
  DECLARE nCreatedDate      DOUBLE(13,3);
  DECLARE nPermission       TINYINT(1) DEFAULT 0;
  DECLARE nCollectionID     BIGINT(20) DEFAULT 0;
  DECLARE nChannelID        BIGINT(20) DEFAULT 0;
  DECLARE vCalendarUri      VARCHAR(255) DEFAULT '';
  --
   SELECT co.user_id = pnUserID, csm.member_user_id = pnUserID AND shared_status = 1, cn.user_id = pnUserID
         ,co.is_trashed, co.id, cn.created_date, cn.channel_id
         ,co.calendar_uri calendar_uri
     INTO isOwner, isMember, isNotiOwner
         ,isTrash, nCollectionID, nCreatedDate, nChannelID
         ,vCalendarUri
     FROM collection_notification cn
LEFT JOIN collection co ON (co.id = cn.collection_id)
LEFT JOIN collection_shared_member csm ON (co.id = csm.collection_id AND (co.user_id = pnUserID OR member_user_id = pnUserID))
LEFT JOIN conference_member cm ON (cn.channel_id = cm.channel_id AND cm.revoke_time = 0 AND cm.user_id = pnUserID)
   WHERE cn.id = pnNotiID
LIMIT 1;
  
  IF ifnull(pnPermission, 0) > 0 AND pnCollectionID = nCollectionID THEN
    -- inheritance permission FROM last request
    SET nPermission = pnPermission;
    --
  ELSE
    -- CHECK permission
    SET nPermission = c2023_checkCollectionNotificationPermission(nChannelID, nCollectionID, pnUserId);
  END IF;
  --
  -- CHECK owner notification WITH isNotiOwner
  IF nPermission < 1 AND NOT isNotiOwner THEN
    -- 
    SELECT nPermission id;
    LEAVE n2023_updateNotificationStatusForUser;
    --
  END IF; 
  -- CHECK permission
  IF isTrash > 0 OR (isOwner = 0 AND isMember = 0) THEN
    --
    SELECT 0 id;
    LEAVE n2023_updateNotificationStatusForUser;
    --
  END IF;
  --
  SET nID = n2023_createUserNotification(pnNotiID, pnStatus, NULL, pdActionTime, nCreatedDate, pnUpdatedDate, NULL, pnUserID, pvEmail);
  -- CHECK deleted notification
  IF nID <= 0 THEN
    --
    SELECT nID id;
    LEAVE n2023_updateNotificationStatusForUser;
    --
  END IF;
  --
   SELECT cn.id,
          CASE 
             WHEN cn.object_type IN ('EMAIL', 'GMAIL', 'GMAIL365') THEN cn.email
             ELSE ifnull(cn.actor, cn.email)
          END email
     ,cn.collection_id, cn.object_uid, cn.object_type
         ,cn.content, cn.comment_id, cn.account_id, cn.category
         ,ifnull(un.action_time, 0) action_time
         ,cn.created_date
         ,un.updated_date
         ,ifnull(un.`status`, 0) `status`
         ,cn.`action`, nPermission permission
         ,cn.channel_id channel_id
         ,ifnull(vCalendarUri, '') calendar_uri
     FROM collection_notification cn
     JOIN user_notification un ON (cn.id = un.collection_notification_id)
    WHERE un.collection_notification_id = pnNotiID
      AND un.user_id = pnUserID
      AND cn.id = pnNotiID;
  --
END