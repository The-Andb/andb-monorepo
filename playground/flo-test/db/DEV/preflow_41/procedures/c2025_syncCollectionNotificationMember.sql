CREATE PROCEDURE `c2025_syncCollectionNotificationMember`(pnCollectionId       BIGINT(20)
                                                          ,pvCalendarUri        VARCHAR(255)
                                                          ,pnAccess             TINYINT
                                                          ,pvSharedEmail        VARCHAR(255)
                                                          ,pnMemberUserId       BIGINT(20)
                                                          ,pnUserId             BIGINT(20)
                                                          ,pnCsmId              BIGINT(20)
                                                          ,pnSharedStatus       TINYINT)
BEGIN
  DECLARE nRecordExists INT DEFAULT 0;
  --
  -- IF shared_status = 4 (LEAVED), DELETE the record
  IF pnSharedStatus = 4 THEN
    DELETE FROM collection_notification_member
     WHERE collection_id = pnCollectionId
       AND member_user_id = pnMemberUserId;
  ELSE
    -- CHECK IF record EXISTS
    SELECT COUNT(*) INTO nRecordExists
      FROM collection_notification_member cnm
     WHERE cnm.collection_id = pnCollectionId
       AND cnm.member_user_id = pnMemberUserId;
    --
    -- IF record doesn't exist, INSERT it
    IF nRecordExists = 0 THEN
      CALL c2025_insertCollectionNotificationMember(
        pnCollectionId, pvCalendarUri, pnAccess, pvSharedEmail,
        pnMemberUserId, pnUserId, pnCsmId, pnSharedStatus
      );
    ELSE
      -- IF record EXISTS, UPDATE it
      CALL c2025_updateCollectionNotificationMember(
        pnCollectionId, pnMemberUserId, pvCalendarUri, pnAccess, pnSharedStatus
      );
    END IF;
  END IF;
  --
END