CREATE FUNCTION `n2024_afterCreateNotification4SharedCollection`(
pnNotiId           BIGINT(20)
,pnCollectionId    BIGINT(20)
,pvObjectType      VARBINARY(50)
,pnAction          INT(11)
,pvAssigner        VARCHAR(100)
,pvAssignee        TEXT
,pnActionTime      DOUBLE(13,3)
,pnCreatedDate     DOUBLE(13,3)
,pnUpdatedDate     DOUBLE(13,3)
) RETURNS INT
BEGIN
  --
  DECLARE no_more_rows    boolean;
  DECLARE nCount          INT DEFAULT 0;
  DECLARE nReturn         INT DEFAULT 0;
  DECLARE nID             BIGINT(20);
  DECLARE nUserID         BIGINT(20);
  DECLARE vEmail          VARCHAR(100);
  DECLARE vMemberUri      VARCHAR(255);
  DECLARE vMemberEmail    VARCHAR(100);
  DECLARE nMemberUserId   BIGINT(20);
  DECLARE vOwnerUri       VARCHAR(255);
  DECLARE vOwnerUsername  VARCHAR(100);
  DECLARE nOwnerUserId    BIGINT(20);
  DECLARE nChannelId      BIGINT(20);
  # Start of: main script;
   DECLARE csm_cursor CURSOR FOR
    SELECT co.user_id, usr.email, co.channel_id
          ,co.calendar_uri member_calendar_uri, usr.email member_email, usr.id member_user_id
          ,co.calendar_uri owner_calendar_uri, usr.username owner_username, usr.id owner_user_id
      FROM collection co
      JOIN user usr ON (co.user_id = usr.id)
     WHERE co.id = pnCollectionId
     UNION
    SELECT csm.member_user_id user_id, csm.shared_email email, co.channel_id
          ,csm.calendar_uri member_calendar_uri, csm.shared_email member_email, csm.member_user_id
          ,co.calendar_uri owner_calendar_uri, usr.username owner_username, usr.id owner_user_id
      FROM collection_shared_member csm
      JOIN collection co ON (csm.collection_id = co.id)
      JOIN `user` usr ON (usr.id = co.user_id)
     WHERE csm.collection_id = pnCollectionId
       AND csm.shared_status = 1; -- joined only
  # END of: main script
  DECLARE CONTINUE handler FOR NOT found SET no_more_rows = TRUE;
  --
  OPEN csm_cursor;
  --
   csm_loop: LOOP
  -- start LOOP member_cursor
  FETCH csm_cursor 
   INTO nUserID, vEmail, nChannelId
       ,vMemberUri, vMemberEmail, nMemberUserId
       ,vOwnerUri, vOwnerUsername, nOwnerUserId;
  -- stop LOOP WHEN no_more_rows
  IF (no_more_rows) THEN
    CLOSE csm_cursor;
    LEAVE csm_loop;
  END IF;
  # main UPDATE
  -- CREATE user notification FOR tracking
  SET nReturn = n2025_createUserNotification(pnNotiId, 0, 0, pnActionTime
                ,pnCollectionId, nChannelId
                ,vMemberUri, vMemberEmail, nMemberUserId
                ,vOwnerUri ,vOwnerUsername, nOwnerUserId
                ,pnCreatedDate, pnUpdatedDate, NULL, nUserID, vEmail);
  -- increase unread badges
  SET nReturn = n2024_increaseNotificationBadge(
      pnNotiId,
      pnCollectionId,
      pvObjectType,
      pnAction,
      pvAssigner,
      pvAssignee,
      pnCreatedDate,
      pnUpdatedDate,
      nUserID,
      vEmail
    );
  --
  SET nCount = nCount + 1;
  # main UPDATE
  --
  END LOOP csm_loop;
  --
  RETURN nCount;
  --
END