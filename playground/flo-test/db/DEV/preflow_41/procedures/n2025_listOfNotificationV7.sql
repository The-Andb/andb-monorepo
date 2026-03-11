CREATE PROCEDURE `n2025_listOfNotificationV7`(
   pnCollectionId     BIGINT(20)
  ,pnChannelId        BIGINT(20)
  ,pvIds              TEXT
  ,pnModifiedGTE      DOUBLE(14,4)
  ,pnModifiedLT       DOUBLE(14,4)
  ,pnMinId            BIGINT(20)
  ,pnPageSize         INTEGER(11)
  ,pnPageNo           INTEGER(11)
  ,pvSort             VARCHAR(128)
  ,pvStatus           VARCHAR(20)    -- AND 0: ALL (DEFAULT) - 1: New - 2: READ - 3: Unread
  ,pvObjectType       VARBINARY(250) -- OR VEVENT, VTODO, VJOURNAL, URL, CHAT, COMMENT,..
  ,pvCategory         VARCHAR(100)    -- OR 0, 1, 2, 3, 4 
  ,pvAction           TEXT           -- OR
  ,pvAssignment       VARCHAR(20)    -- OR 0: ALL (DEFAULT) - 1: NOT Assigned - 2: Assigned TO Me - 3: Assigned BY Me
  ,pnIncludeShared    TINYINT(1)     -- != 1 - NOT GET shared kanban
  ,pnIncludeReaction  TINYINT(1)     -- 1: chat, 2: comment, 3: BOTH
  ,pnIncludePersonal  TINYINT(1)     -- != 1 - NOT GET personal notification
  ,pnActionByMe       TINYINT(1)
  ,pnUserId           BIGINT(20)
  ,pvUsername         VARCHAR(100)
  ,pnVip              TINYINT(1)
  )
BEGIN
  -- only SHOW notification edited FOR mentioned member
  DECLARE nTimeToDel        DOUBLE;
  DECLARE vStatus           VARCHAR(20) DEFAULT ifnull(pvStatus, '0');
  DECLARE vAssignment       VARCHAR(20) DEFAULT ifnull(pvAssignment, '0'); 
  DECLARE nOFFSET           INT(11) DEFAULT 0;  
  DECLARE nLimit            INT(11) DEFAULT 5000;
  DECLARE nActionByMe       INT(11) DEFAULT ifnull(pnActionByMe, 1);
  DECLARE vFieldSort        VARCHAR(50) DEFAULT REPLACE(REPLACE(IFNULL(pvSort, ''), '-', ''), '+', '');                                              
  DECLARE vSort             VARCHAR(50) DEFAULT IF(IFNULL(pvSort, '') <> '' -- DEFAULT +: ASC
                                                  AND NOT instr(pvSort, '-') 
                                                  AND NOT instr(pvSort, '+')
                                                 ,concat('+', pvSort), pvSort);
  DECLARE nModifiedLT DOUBLE(14,4) DEFAULT IF(ifnull(pnModifiedLT, 0) > 0, pnModifiedLT, unix_timestamp() + 1);
  DECLARE nModifiedGTE DOUBLE(14,4) DEFAULT IF(ifnull(pnModifiedGTE, 0) > 0, pnModifiedGTE, 0);
  DECLARE nIncludeReaction TINYINT(1) DEFAULT ifnull(pnIncludeReaction, 0);
  DECLARE nIncludeShared TINYINT(1) DEFAULT ifnull(pnIncludeShared, 0);
  DECLARE nIncludePersonal TINYINT(1) DEFAULT ifnull(pnIncludePersonal, 0);
  --
  IF ifnull(pvSort, 'NA') <> 'NA' THEN
    --
    SET nOFFSET = IF(ifnull(pnPageNo, 0) = 0, 0, (pnPageNo - 1) * pnPageSize);
    --
  END IF;
  --
  SET nTimeToDel = n2025_getMinCreatedDateToShowNotification(pnModifiedGTE, pnUserId);
  --
  SELECT cn.id
        ,CASE
            WHEN cn.object_type IN ("EMAIL", "GMAIL", "EMAIL365")
            THEN cn.email
            ELSE ifnull(cn.actor, cn.email)
         END `email`
        ,cn.collection_id, ifnull(cn.channel_id, 0) channel_id
        ,cn.object_uid, cn.object_type
        ,CASE
            WHEN cn.`action` IN (6, 61) AND un.has_mention = 1
            THEN 63 -- VIRTUAL action: 63 - MENTIONED COMMENT
            WHEN cn.`action` IN (30, 31) AND un.has_mention = 1
            THEN 33 -- VIRTUAL action: 33 - MENTIONED CHAT
            ELSE cn.action
         END `action`
        ,cn.content, cn.comment_id
        ,cn.created_date, COALESCE(un.action_time, cn.action_time, 0) action_time
        ,ifnull(un.updated_date, cn.updated_date) updated_date
        ,cnm.member_calendar_uri, cnm.member_email, cnm.member_user_id
        ,cnm.owner_calendar_uri, cnm.owner_email, cnm.owner_user_id
        ,un.status
        ,cn.account_id, cn.kanban_id, cn.assignees, ifnull(cn.emoji_unicode, '') emoji_unicode, cn.account_id, cn.category
        ,ifnull(cn.actor, '') actor, cn.is_reply
        ,IF(cn.object_type NOT IN ('VEVENT', 'VJOURNAL', 'VTODO') 
             ,''
             ,concat("/calendarserver.php/calendars/"
               ,cnm.owner_email, "/"
               ,cnm.owner_calendar_uri, "/"
               ,CAST(CONVERT(cn.object_uid USING cp1251) AS CHAR CHARACTER SET latin1)
               ,".ics"
               )
             ) object_href
     FROM user_notification un
     JOIN collection_notification_member cnm ON (un.user_id = cnm.member_user_id AND un.cnm_id = cnm.id)
     JOIN collection_notification cn ON (un.collection_notification_id = cn.id)
    WHERE un.user_id = pnUserId
      AND cn.created_date >= nTimeToDel
      AND (isnull(pnMinId) OR cn.id > pnMinId)
      AND (isnull(pvObjectType) OR find_in_set(cn.object_type, pvObjectType))
      AND (isnull(pvIds) OR FIND_IN_SET(cn.id, pvIds))
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
      AND n2025_notificationModifedFilter(un.id, cn.updated_date, un.updated_date, nModifiedLT, nModifiedGTE)
      AND n2025_notificationActionFilter(pvAction, cn.action, un.has_mention)
      AND n2025_notificationStatusFilter(vStatus, un.status, cn.created_date)
      AND n2025_notificationAssignmentFilter(vAssignment, cn.object_uid, cn.object_type, cn.action, cn.assignees, pvUsername, cn.email)
      AND n2025_notificationVipFilter(pnVip, cn.actor, cn.object_type, cn.action, pvUsername, cn.email)
      AND IF(nIncludeReaction IN (1,3), 1, cn.`action` <> 23)
      AND IF(nIncludeReaction IN (2,3), 1, cn.`action` <> 24)
      AND (nIncludeShared = 1 OR cn.`action` NOT IN (20, 21, 22))
      AND (nIncludePersonal = 1 OR cn.`action` NOT IN (19, 30, 31, 70, 80, 81))
    GROUP BY cn.id
    ORDER BY
        (CASE
           --
           WHEN NOT isnull(pnModifiedLT) THEN cn.updated_date
           WHEN isnull(pnMinId) AND INSTR(vSort, "-") THEN
             --
             CASE vFieldSort
               --
               WHEN 'action_time' THEN cn.action_time               
               WHEN 'updated_date' THEN cn.updated_date
               WHEN 'created_date' THEN cn.created_date
               --
             END
           --
         END) DESC,
        (CASE
           --
           WHEN NOT isnull(pnMinId) THEN cn.id
           WHEN NOT isnull(pnModifiedGTE) THEN cn.updated_date
           WHEN isnull(pnMinId) AND INSTR(vSort, "+") THEN
             --
             CASE vFieldSort 
               --
               WHEN 'action_time' THEN cn.action_time               
               WHEN 'updated_date' THEN cn.updated_date
               WHEN 'created_date' THEN cn.created_date
               --
              END
           --
         END) ASC
        
    LIMIT pnPageSize
   OFFSET nOFFSET;
  --
END