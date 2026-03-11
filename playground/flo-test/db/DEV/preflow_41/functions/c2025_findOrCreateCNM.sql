CREATE FUNCTION `c2025_findOrCreateCNM`(
pnCollectionId   BIGINT(20)
,pnChannelId      BIGINT(20)
,pvMemberUri      VARCHAR(255)
,pvMemberEmail    VARCHAR(100)
,pnMemberUserId   BIGINT(20)
,pvOwnerUri       VARCHAR(255)
,pvOwnerUsername  VARCHAR(100)
,pnOwnerUserId    BIGINT(20)
) RETURNS BIGINT
BEGIN
  --
  DECLARE nCNMID         BIGINT(20);
  DECLARE nCalendarId    INT(20) DEFAULT 0;
  --
  -- find existing cnm
  SELECT ifnull(max(cnm.id), 0)
    INTO nCNMID
    FROM collection_notification_member cnm
   WHERE cnm.collection_id = pnCollectionId
     AND cnm.channel_id = pnChannelId
     AND cnm.member_user_id = pnMemberUserId;
  --
  IF nCNMID = 0 THEN
    --
    IF ifnull(pvOwnerUri, '') <> '' THEN
      --
      SELECT ci.calendarid
        INTO nCalendarId
        FROM calendarinstances ci
       WHERE ci.uri = pvOwnerUri
       LIMIT 1;
      --
    END IF;
    --
    INSERT INTO collection_notification_member 
    (collection_id, calendarid, channel_id
     ,member_calendar_uri, member_email, member_user_id
     ,owner_calendar_uri ,owner_email, owner_user_id
     ,fk_collection_id, fk_channel_id, fk_cm_id, fk_csm_id, is_active
     ,created_date, updated_date)
    VALUES  (pnCollectionId, nCalendarId, pnChannelId
     ,pvMemberUri, pvMemberEmail, pnMemberUserId
     ,pvOwnerUri, pvOwnerUsername, pnOwnerUserId
     ,nullif(pnCollectionId, 0), nullif(pnChannelId, 0), NULL, NULL, 1
     ,UNIX_TIMESTAMP(now(3)), UNIX_TIMESTAMP(now(3)));
    --
    SET nCNMID = LAST_INSERT_ID();
    --
  END IF;  
  --
  RETURN nCNMID;
  --
END