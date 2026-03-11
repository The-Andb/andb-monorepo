CREATE FUNCTION `n2024_afterCreateNotification4SharedCollection`(
pnNotiId           BIGINT(20)
,pnCollectionId    BIGINT(20)
,pnChannelId       BIGINT(20) -- high priority
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
 
  # Start of: main script;
    DECLARE cm_cursor CURSOR FOR
     SELECT cm.user_id, cm.email
       FROM conference_member cm
      WHERE cm.channel_id = pnChannelId
        AND cm.revoke_time = 0
        AND cm.user_id > 0;
    --
   DECLARE csm_cursor CURSOR FOR
    SELECT co.user_id, u.email
      FROM collection co
      JOIN user u ON (co.user_id = u.id)
     WHERE co.id = pnCollectionId
     UNION
    SELECT csm.member_user_id user_id, csm.shared_email email
      FROM collection_shared_member csm
     WHERE csm.collection_id = pnCollectionId
       AND csm.shared_status = 1; -- joined only
  
  # END of: main script
  DECLARE CONTINUE handler FOR NOT found SET no_more_rows = TRUE;
  --
  IF pnChannelId > 0 THEN
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
    END LOOP cm_loop;
    --
  ELSE
    --
    OPEN csm_cursor;
    --
     csm_loop: LOOP
    -- start LOOP member_cursor
    FETCH csm_cursor 
     INTO nUserID, vEmail;
    -- stop LOOP WHEN no_more_rows
    IF (no_more_rows) THEN
      CLOSE csm_cursor;
      LEAVE csm_loop;
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
  END IF;
  
  --
  RETURN nCount;
  --
END