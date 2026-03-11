CREATE PROCEDURE `c2025_insertCollectionNotificationMember`(pnCollectionId       BIGINT(20)
                                                           ,pvCalendarUri        VARCHAR(255)
                                                           ,pnAccess             TINYINT
                                                           ,pvSharedEmail        VARCHAR(255)
                                                           ,pnMemberUserId       BIGINT(20)
                                                           ,pnUserId             BIGINT(20)
                                                           ,pnCsmId              BIGINT(20)
                                                           ,pnSharedStatus       TINYINT)
BEGIN
  DECLARE vOwnerUri          VARCHAR(255);
  DECLARE vOwnerUsername     VARCHAR(255);
  DECLARE nChannelId         BIGINT(20) DEFAULT 0;
  --
  -- GET owner information
  SELECT co.calendar_uri, co.channel_id, usr.username
    INTO vOwnerUri, nChannelId, vOwnerUsername
    FROM collection co
    JOIN user usr ON co.user_id = usr.id
   WHERE co.id = pnCollectionId;
  --
  -- INSERT record
  INSERT INTO collection_notification_member 
           (collection_id, calendarid, channel_id, access
            ,member_calendar_uri, member_email, member_user_id
            ,owner_calendar_uri, owner_email, owner_user_id
            ,fk_collection_id, fk_channel_id, fk_cm_id, fk_csm_id, is_active
            ,created_date, updated_date)
    VALUES
            (pnCollectionId, 0 -- will supply after calendarinstances
            ,nChannelId, pnAccess
            ,pvCalendarUri, pvSharedEmail, pnMemberUserId
            ,vOwnerUri, vOwnerUsername, pnUserId
            ,pnCollectionId, nChannelId, NULL, pnCsmId, 0
            ,UNIX_TIMESTAMP(now(3)), UNIX_TIMESTAMP(now(3)));
  --
END