CREATE FUNCTION `n2025_afterCreateNotification4Conference`(
pnNotiId           BIGINT(20)
,pnCollectionId    BIGINT(20)
,pnChannelId       BIGINT(20) -- high priority
,pvObjectType      VARBINARY(50)
,pnAction          INT(11)
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
 
  # Start of: main script;
    DECLARE cm_cursor CURSOR FOR
     SELECT cm.user_id, cm.email
       FROM conference_member cm
      WHERE cm.channel_id = pnChannelId
        AND cm.revoke_time = 0
        AND cm.user_id > 0;
  # END of: main script
  DECLARE CONTINUE handler FOR NOT found SET no_more_rows = TRUE;
  --
  OPEN cm_cursor;
  --
  cm_loop: LOOP
  -- start LOOP member_cursor
  FETCH cm_cursor 
   INTO nUserID, vEmail;
  -- stop LOOP WHEN no_more_rows
  IF (no_more_rows) THEN
    CLOSE cm_cursor;
    LEAVE cm_loop;
  END IF;
  # main UPDATE
  -- CREATE user notification FOR tracking
  SET nReturn = n2023_createUserNotification(pnNotiId, 0, 0, pnActionTime, pnCreatedDate, pnUpdatedDate, NULL, nUserID, vEmail);
  -- increase unread badges
  SET nReturn = n2024_increaseNotificationBadge(
      pnNotiId,
      pnCollectionId,
      pvObjectType,
      pnAction,
      '',
      '',
      pnCreatedDate,
      pnUpdatedDate,
      nUserID,
      vEmail
    );
  --
  SET nCount = nCount + 1;
  # main UPDATE
  --
  END LOOP cm_loop;
  --
  RETURN nCount;
  --
END