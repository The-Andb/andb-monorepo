CREATE PROCEDURE `c2025_updateCollectionNotificationMember`(pnCollectionId       BIGINT(20)
                                                           ,pnMemberUserId       BIGINT(20)
                                                           ,pvCalendarUri        VARCHAR(255)
                                                           ,pnAccess             TINYINT
                                                           ,pnSharedStatus       TINYINT)
BEGIN
  --
  UPDATE collection_notification_member cnm
     SET cnm.is_active = IF(pnSharedStatus = 1, 1, 0)
        ,cnm.member_calendar_uri = IF(pnSharedStatus = 1, pvCalendarUri, cnm.member_calendar_uri)
        ,cnm.access = pnAccess
        ,cnm.updated_date = UNIX_TIMESTAMP(now(3))
   WHERE cnm.collection_id = pnCollectionId
     AND cnm.member_user_id = pnMemberUserId;
  --
END