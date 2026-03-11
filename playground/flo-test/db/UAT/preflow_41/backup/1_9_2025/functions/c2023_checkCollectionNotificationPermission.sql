CREATE FUNCTION `c2023_checkCollectionNotificationPermission`(
pnChannelId           BIGINT(20)
,pnCollectionId        BIGINT(20)
,pnUserId              BIGINT(20)
) RETURNS TINYINT(1)
BEGIN
  -- CHECK permisstion be FOR operate ON shared collection
  DECLARE isMemberConf      boolean;
  DECLARE nPermission       TINYINT(1) DEFAULT 0;
  --
  SET nPermission = c2023_checkCollectionPermission(pnCollectionID, pnUserId);
  --
  IF nPermission > 0 THEN
    RETURN nPermission;
  END IF;
  -- CHECK permission conference
  SELECT cm.user_id = pnUserID
    INTO isMemberConf
    FROM conference_channel cc
    JOIN conference_member cm ON cc.id = cm.channel_id
   WHERE cm.user_id = pnUserID
     AND cc.id = pnChannelId
     AND cm.revoke_time = 0
     AND cc.is_trashed = 0;
  --
  RETURN isMemberConf;
  --
END