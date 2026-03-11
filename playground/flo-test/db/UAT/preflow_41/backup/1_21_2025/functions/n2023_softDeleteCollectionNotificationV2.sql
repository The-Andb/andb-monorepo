CREATE FUNCTION `n2023_softDeleteCollectionNotificationV2`(
pnNotiID            BIGINT(20)
,pnDeletedDate      DOUBLE(13,3)
,pnUserId           BIGINT(20)
,pvEmail            VARCHAR(100)
) RETURNS BIGINT
BEGIN
  -- DELETE notification collection FOR user
  # -3. Collection was NOT found OR trashed
  # -2. NOT shared collection
  # -1. access denied
  --
  DECLARE nCollectionID       BIGINT(20) DEFAULT 0;
  DECLARE nReturn             BIGINT(20) DEFAULT 0;
  DECLARE nID                 BIGINT(20) DEFAULT 0;
  DECLARE nPermission         TINYINT(1) DEFAULT 0;
  DECLARE nIsTrash            TINYINT(1) DEFAULT 0;
  DECLARE isNotiOwner         boolean;
  DECLARE nChannelID          BIGINT(20) DEFAULT 0;
  -- 0. validate parameters
  IF isnull(pnNotiID) OR isnull(pnUserId) THEN
    -- 
    RETURN -1; -- access denied
    --
  END IF;
  -- 1. CHECK exist collection, channel, owner
  SELECT ifnull(max(cn.id), 0), cn.collection_id, cn.channel_id, cn.user_id = pnUserID, co.is_trashed
    INTO nID, nCollectionID, nChannelID, isNotiOwner, nIsTrash
    FROM collection_notification cn
    JOIN collection co ON (cn.collection_id = co.id)
   WHERE cn.id = pnNotiID;
  -- 1.1 
  IF nID = 0 THEN
    --
    RETURN 0;
    --
  END IF;
  -- 2. CHECK permission
  SET nPermission = c2023_checkCollectionNotificationPermission(nChannelID, nCollectionID, pnUserId);
  --
  IF nIsTrash OR (nPermission < 1 AND NOT isNotiOwner) THEN
    -- 
    RETURN nPermission; -- NOT DELETE
    --
  END IF; 
  -- 3. negative DELETE FOR user notification
  SET nID = n2023_createUserNotification(pnNotiID, 0, 0, NULL, pnDeletedDate, pnDeletedDate, pnDeletedDate, pnUserID, pvEmail);
  -- already deleted
  IF nID < 1 THEN
    --
    RETURN nID;
    --
  END IF;
  -- 4. CREATE deleted item FOR this user
   # main DELETE
  INSERT INTO deleted_item
        (item_id, item_type, user_id, item_uid, is_recovery, created_date, updated_date)
  value (pnNotiID, 'COLLECTION_NOTIFICATION', pnUserID, '', 0, pnDeletedDate, pnDeletedDate);
  -- 5. CHECK ALL UN deleted -> DELETE CN permantly
  SET nReturn = n2023_checkToPermanentlyDeleteNotification(pnNotiID, nCollectionID);
  -- 6. decrease notification badge
  SET nReturn = n2024_decreaseNotificationBadge(
        pnNotiID,
        pnDeletedDate,
        pnDeletedDate,
        pnUserID,
        pvEmail
      );
  --
  RETURN pnNotiID;
  --
END