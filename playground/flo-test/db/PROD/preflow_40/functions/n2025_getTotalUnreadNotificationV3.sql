CREATE FUNCTION `n2025_getTotalUnreadNotificationV3`(
 pnCollectionId     BIGINT(20)
,pnChannelId        BIGINT(20)
,pvStatus           VARCHAR(20)    -- AND 0: ALL (DEFAULT) - 1: New - 2: READ - 3: Unread
,pvObjectType       VARBINARY(250) -- OR VEVENT, VTODO, VJOURNAL, URL
,pvCategory         VARCHAR(100)    -- OR 0, 1, 2, 3, 4 
,pvAction           TEXT           -- OR
,pvAssignment       VARCHAR(20)    -- OR 0: ALL (DEFAULT) - 1: NOT Assigned - 2: Assigned TO Me - 3: Assigned BY Me
,pnIncludeShared    TINYINT(1)
,pnIncludeReaction  TINYINT(1)     -- 1: chat, 2: comment, 3: BOTH
,pnIncludePersonal  TINYINT(1)
,pnActionByMe       TINYINT(1)
,pnVip              TINYINT(1)
,pnUserId           BIGINT(20)
,pvUsername         VARCHAR(100)
) RETURNS INT
BEGIN
  -- this fn TO GET total at API GET notification list
  DECLARE nTimeToDel        DOUBLE;
  DECLARE vStatus           VARCHAR(20) DEFAULT ifnull(pvStatus, '0');
  DECLARE vAssignment       VARCHAR(20) DEFAULT ifnull(pvAssignment, '0');
  DECLARE nReturn           INT(11) DEFAULT 0;
  DECLARE nActionByMe       INT(11) DEFAULT ifnull(pnActionByMe, 1);
  --
  IF pnCollectionId IS NULL AND pnChannelId IS NULL THEN
    --
    RETURN 200;
    --
  END IF;
  --
  SET nTimeToDel = n2025_getMinCreatedDateToShowNotification(0, pnUserId);
  --
  SELECT count(cn.id)
    INTO nReturn
    FROM user_notification un
     JOIN collection_notification_member cnm ON (un.user_id = cnm.member_user_id AND un.cnm_id = cnm.id)
     JOIN collection_notification cn ON (un.collection_notification_id = cn.id)
    WHERE un.user_id = pnUserId
      AND cn.created_date >= nTimeToDel
      AND (isnull(pvObjectType) OR find_in_set(cn.object_type, pvObjectType))
      AND (cn.action NOT IN (31, 61) OR un.has_mention = 1)
      AND (pnCollectionId IS NULL OR cn.collection_id = pnCollectionId)
      AND (pnChannelId IS NULL OR cn.channel_id = pnChannelId)
      AND (cn.`action` NOT IN (23, 24, 123, 124, 125) OR cn.user_id = pnUserId)
      AND (nActionByMe = 1 OR (nActionByMe = 0 AND ifnull(cn.actor, cn.email) <> pvUsername))
      AND (
          pvCategory IS NULL 
          OR (
          (cn.object_type <> 'VTODO'
           OR
           FIND_IN_SET(cn.category, pvCategory)
          )
        )
      )
      AND n2025_notificationActionFilter(pvAction, cn.action, un.has_mention)
      AND n2025_notificationStatusFilter(vStatus, un.status, cn.created_date)
      AND (pvAssignment IS NULL OR n2025_notificationAssignmentFilter(vAssignment, cn.object_uid, cn.object_type, cn.action, cn.assignees, pvUsername, cn.email))
      AND n2025_notificationVipFilter(pnVip, cn.actor, cn.object_type, cn.action, pvUsername, cn.email)
      AND IF(pnIncludeReaction IN (1,3), 1, cn.`action` <> 23)
      AND IF(pnIncludeReaction IN (2,3), 1, cn.`action` <> 24)
      AND (pnIncludeShared = 1 OR cn.`action` NOT IN (20, 21, 22))
      AND (pnIncludePersonal = 1 OR cn.`action` NOT IN (19, 30, 31, 70, 80, 81))
      ;
 RETURN IF(nReturn > 200, 200, nReturn);
END