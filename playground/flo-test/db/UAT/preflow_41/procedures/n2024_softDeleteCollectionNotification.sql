CREATE PROCEDURE `n2024_softDeleteCollectionNotification`(
pnPermission        TINYINT(1)
,pnCollectionID     BIGINT(20)
,pnNotiID           BIGINT(20)
,pnDeletedDate      DOUBLE(13,3)
,pnUserId           BIGINT(20)
,pvEmail            VARCHAR(100)
)
n2024_softDeleteCollectionNotification: BEGIN
  -- DELETE notification collection FOR user
  # -3. Collection was NOT found OR trashed
  # -2. NOT shared collection
  # -1. access denied
  --
  DECLARE nCollectionID       BIGINT(20) DEFAULT 0;
  DECLARE nReturn             BIGINT(20) DEFAULT 0;
  DECLARE nID                 BIGINT(20) DEFAULT 0;
  DECLARE nIDDel              BIGINT(20) DEFAULT 0;
  DECLARE nPermission         TINYINT(1) DEFAULT 0;
  DECLARE nIsTrash            TINYINT(1) DEFAULT 0;
  DECLARE isNotiOwner         boolean;
  DECLARE nChannelID          BIGINT(20) DEFAULT 0;
  DECLARE nAction             BIGINT(20) DEFAULT 0;
  -- 0. validate parameters
  IF isnull(pnNotiID) OR isnull(pnUserId) THEN
    -- 
    SELECT -1 id; -- access denied
    LEAVE n2024_softDeleteCollectionNotification;
    --
  END IF;
  -- 1. CHECK exist collection, channel, owner
  SELECT ifnull(max(cn.id), 0), cn.collection_id, cn.channel_id, cn.user_id = pnUserID, ifnull(co.is_trashed, 0), cn.action
    INTO nID, nCollectionID, nChannelID, isNotiOwner, nIsTrash, nAction
    FROM collection_notification cn
    LEFT JOIN collection co ON (cn.collection_id = co.id)
   WHERE cn.id = pnNotiID;
  -- 1.1 
  IF nID = 0 THEN
    --
    SELECT 0 id;
    LEAVE n2024_softDeleteCollectionNotification;
    --
  END IF;
  -- 2. CHECK permission
  IF ifnull(pnPermission, 0) > 0 AND pnCollectionID = nCollectionID THEN
    -- inheritance permission FROM last request
    SET nPermission = pnPermission;
    --
  ELSE
    -- CHECK permission
    SET nPermission = c2023_checkCollectionNotificationPermission(nChannelID, nCollectionID, pnUserId);
  END IF;
  --
  IF nIsTrash OR (nPermission < 1 AND NOT isNotiOwner) THEN
    -- 
    SELECT nPermission id; -- NOT DELETE
    LEAVE n2024_softDeleteCollectionNotification;
    --
  END IF; 
  -- 3. CHECK aldready deleted
  SELECT ifnull(max(di.id), 0)
    INTO nIDDel
    FROM deleted_item di
   WHERE di.item_type = 'COLLECTION_NOTIFICATION' 
     AND di.user_id = pnUserID 
     AND di.item_id = pnNotiID;
  --
  IF nIDDel > 0 THEN 
    --
    SELECT -1 id;
    LEAVE n2024_softDeleteCollectionNotification;
    --
  END IF;
  --
  DELETE FROM user_notification
   WHERE collection_notification_id = pnNotiID
     AND user_id = pnUserID;
  -- 4. CREATE deleted item FOR this user
   # main DELETE
  INSERT INTO deleted_item
        (item_id, item_type, user_id, item_uid, is_recovery, created_date, updated_date)
  value (pnNotiID, 'COLLECTION_NOTIFICATION', pnUserID, '', 0, pnDeletedDate, pnDeletedDate);
  -- 5. CHECK ALL UN deleted -> DELETE CN permantly
  -- TO reuse for deleted_item
  -- SET nReturn = n2023_checkToPermanentlyDeleteNotification(pnNotiID, nCollectionID);
  -- 6. decrease notification badge
  --   SET nReturn = n2024_decreaseNotificationBadge(
  --         pnNotiID,
  --         pnDeletedDate,
  --         pnDeletedDate,
  --         pnUserID,
  --         pvEmail
  --       );
  --
  SELECT pnNotiID id, nPermission permission, nCollectionID collection_id, nAction `action`;
  --
END