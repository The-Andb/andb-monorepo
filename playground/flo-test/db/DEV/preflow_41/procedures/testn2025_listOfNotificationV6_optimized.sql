CREATE PROCEDURE `testn2025_listOfNotificationV6_optimized`(
   pnCollectionId     BIGINT(20)
  ,pnChannelId        BIGINT(20)
  ,pvIds              TEXT
  ,pnModifiedGTE      DOUBLE(14,4)
  ,pnModifiedLT       DOUBLE(14,4)
  ,pnMinId            BIGINT(20)
  ,pvSort             VARCHAR(128)
  ,pvStatus           VARCHAR(20)    -- AND 0: ALL (DEFAULT) - 1: New - 2: READ - 3: Unread
  ,pvObjectType       VARBINARY(250) -- OR VEVENT, VTODO, VJOURNAL, URL, CHAT, COMMENT,..
  ,pvCategory         VARCHAR(100)    -- OR 0, 1, 2, 3, 4 
  ,pvAction           VARCHAR(100)   -- OR
  ,pvAssignment       VARCHAR(20)    -- OR 0: ALL (DEFAULT) - 1: NOT Assigned - 2: Assigned TO Me - 3: Assigned BY Me
  ,pnIncludeShared    TINYINT(1)     -- != 1 - NOT GET shared kanban
  ,pnIncludeReaction  TINYINT(1)     -- 1: chat, 2: comment, 3: BOTH
  ,pnIncludePersonal  TINYINT(1)     -- != 1 - NOT GET personal notification
  ,pnActionByMe       TINYINT(1)
  ,pnVip              TINYINT(1)
  ,pnPageSize         INTEGER(11)
  ,pnPageNo           INTEGER(11)
  ,pnUserId           BIGINT(20)
  ,pvUsername         VARCHAR(100)
  )
BEGIN
  -- Variables declaration
  DECLARE nTimeToDel        DOUBLE;
  DECLARE vStatus           VARCHAR(20) DEFAULT ifnull(pvStatus, '0');
  DECLARE vAssignment       VARCHAR(20) DEFAULT ifnull(pvAssignment, '0'); 
  DECLARE nOFFSET           INT(11) DEFAULT 0;  
  DECLARE nActionByMe       INT(11) DEFAULT ifnull(pnActionByMe, 1);
  DECLARE vFieldSort        VARCHAR(50) DEFAULT REPLACE(REPLACE(IFNULL(pvSort, ''), '-', ''), '+', '');                                              
  DECLARE vSort             VARCHAR(50) DEFAULT IF(IFNULL(pvSort, '') <> '' 
                                                  AND NOT instr(pvSort, '-') 
                                                  AND NOT instr(pvSort, '+')
                                                 ,concat('+', pvSort), pvSort);
  DECLARE nModifiedLT       DOUBLE(14,4) DEFAULT IF(ifnull(pnModifiedLT, 0) > 0, pnModifiedLT, unix_timestamp() + 1);
  DECLARE nModifiedGTE      DOUBLE(14,4) DEFAULT IF(ifnull(pnModifiedGTE, 0) > 0, pnModifiedGTE, 0);
  
  -- Pagination setup
  IF ifnull(pvSort, 'NA') <> 'NA' THEN
    SET nOFFSET = IF(ifnull(pnPageNo, 0) = 0, 0, (pnPageNo - 1) * pnPageSize);
  END IF;
  
  -- GET minimum time TO SHOW notifications
  SET nTimeToDel = n2025_getMinCreatedDateToShowNotification(pnUserId);
  
  -- Optimized query USING CTEs
  EXPLAIN SELECT cn.id, cn.collection_id, ifnull(cn.channel_id, 0) channel_id, cn.user_id, cn.content
           ,cn.object_type, cn.object_uid, cn.assignees, ifnull(cn.actor, '') actor
           ,COALESCE(un.action_time, cn.action_time, 0) action_time
           ,cn.comment_id, cn.created_date, ifnull(un.updated_date, cn.updated_date) updated_date
           ,cn.kanban_id, ifnull(cn.emoji_unicode,'') emoji_unicode, cn.category, cn.is_reply
           ,un.has_mention
           ,cnm.owner_calendar_uri, cnm.owner_user_id, cnm.owner_email
           ,cnm.member_calendar_uri, cnm.member_email, cnm.member_user_id
           ,cnm.last_seen_chat, cnm.last_seen_call
           ,cn.account_id
          ,cn.object_type, cn.object_uid, cn.assignees, cn.email, cn.actor
          ,cn.kanban_id, cn.emoji_unicode, cn.category, cn.is_reply
          ,un.has_mention
          ,n2025_notificationCallChatReadTransform(cn.object_type
                                                             ,un.`status`
                                                             ,cnm.last_seen_chat
                                                             ,cnm.last_seen_call
                                                             ,cn.created_date
                                                             ,un.updated_date
                                                             ,cn.updated_date) `status`
           ,CASE
               WHEN cn.object_type IN ("EMAIL", "GMAIL", "EMAIL365")
               THEN cn.actor
               ELSE ifnull(cn.actor, '')
            END `email`
           ,CASE
               WHEN cn.`action` IN (6, 61) AND un.has_mention = 1
               THEN 63 -- VIRTUAL action: 63 - MENTIONED COMMENT
               WHEN cn.`action` IN (30, 31) AND un.has_mention = 1
               THEN 33 -- VIRTUAL action: 33 - MENTIONED CHAT
               ELSE cn.`action`
            END `action`
          ,IF(cn.object_type NOT IN ('VEVENT', 'VJOURNAL', 'VTODO') 
               ,''
               ,concat("/calendarserver.php/calendars/"
                 ,cnm.owner_email, "/"
                 ,cnm.owner_calendar_uri, "/"
                 ,CAST(CONVERT(cn.object_uid USING cp1251) AS CHAR CHARACTER SET latin1)
                 ,".ics"
                 )
               ) object_href
          ,COALESCE(
                 (SELECT ce.summary FROM cal_event ce WHERE ce.uid = cn.object_uid AND cn.object_type = 'VEVENT' ORDER BY id DESC LIMIT 1),
                 (SELECT cn1.summary FROM cal_note cn1 WHERE cn1.uid = cn.object_uid AND cn.object_type = 'VJOURNAL' ORDER BY id DESC LIMIT 1),
                 (SELECT ct.summary FROM cal_todo ct WHERE ct.uid = cn.object_uid AND cn.object_type = 'VTODO' ORDER BY id DESC LIMIT 1),
                 (SELECT url.title FROM url WHERE url.uid = cn.object_uid AND cn.object_type = 'URL' ORDER BY id DESC LIMIT 1),
                 ''
             ) last_object_title
      FROM collection_notification_member cnm 
      JOIN collection_notification cn ON (cn.collection_id = cnm.collection_id OR cn.channel_id = cnm.channel_id 
         OR (
           cnm.member_user_id = cn.user_id AND cn.collection_id = 0 AND cn.channel_id = 0
          )
        )
 LEFT JOIN user_notification un ON (un.collection_notification_id = cn.id AND un.user_id = pnUserId)
     WHERE cnm.member_user_id = pnUserId 
       AND cn.created_date >= nTimeToDel
       AND (isnull(pnMinId) OR cn.id > pnMinId)
       AND (isnull(pvObjectType) OR find_in_set(cn.object_type, pvObjectType))
       AND (isnull(pvIds) OR FIND_IN_SET(cn.id, pvIds))
       AND (cn.action NOT IN (31, 61) OR un.has_mention = 1)
       AND un.deleted_date IS NULL
       -- React comment/chat filter
       AND (cn.`action` NOT IN (23, 24) OR cn.user_id = pnUserId)
       -- Modified filter
       AND n2025_notificationModifedFilter(un.id, cn.updated_date, un.updated_date, nModifiedLT, nModifiedGTE)
       -- Action filter
       AND n2025_notificationActionFilter(pvAction, cn.action, un.has_mention)
               -- Status filter (different logic for conference)
        AND (cnm.channel_id > 0 OR (
          -- Conference SPECIFIC status filtering
          (find_in_set(0, vStatus)
           OR (-- 1: New
               IF(find_in_set(1, vStatus), unix_timestamp(now(3) - INTERVAL 1 day) <= cn.created_date, 1)
               -- 2: READ
               AND (vStatus = '1'
                 OR (find_in_set(2, vStatus)
                     AND n2025_notificationCallChatReadTransform(cn.object_type
                                                             ,un.`status`
                                                             ,cnm.last_seen_chat
                                                             ,cnm.last_seen_call
                                                             ,cn.created_date
                                                             ,un.updated_date
                                                             ,cn.updated_date) = 1)
                 -- 3: Unread
                 OR (find_in_set(3, vStatus)
                      AND n2025_notificationCallChatReadTransform(cn.object_type
                                                             ,un.`status`
                                                             ,cnm.last_seen_chat
                                                             ,cnm.last_seen_call
                                                             ,cn.created_date
                                                             ,un.updated_date
                                                             ,cn.updated_date) = 0)
                 -- 4: Closed
                 OR (find_in_set(4, vStatus) AND ifnull(un.status, 0) = 2)
               )
             )
          )
        ))
        AND (cnm.channel_id > 0 OR n2025_notificationStatusFilter(vStatus, un.status, cn.created_date))
       -- Assignment filter
       AND n2025_notificationAssignmentFilter(vAssignment, cn.object_uid, cn.object_type, cn.action, cn.assignees, pvUsername, cn.email)
       -- Shared kanban filter
       AND (ifnull(pnIncludeShared, 0) = 1 OR cn.`action` NOT IN (20, 21, 22))
       -- Reaction filter
       AND IF(ifnull(pnIncludeReaction, 0) IN (1,3), 1, cn.`action` <> 23)
       AND IF(ifnull(pnIncludeReaction, 0) IN (2,3), 1, cn.`action` <> 24)
       -- Personal notification filter
       AND IF(ifnull(pnIncludePersonal, 0) = 1, 1, cn.`action` NOT IN (19, 30, 31, 70, 80, 81))
       -- Action BY me filter
       AND (nActionByMe = 1 OR (nActionByMe = 0 AND ifnull(cn.actor, cn.email) <> pvUsername))
       -- Category filter
       AND (pvCategory IS NULL OR (IF(cn.object_type <> 'VTODO', 1, FIND_IN_SET(cn.category, pvCategory))))
       -- Conference SPECIFIC filters
       AND (cnm.channel_id > 0 OR (
         cn.created_date >= cnm.last_seen_call AND
         (cn.action NOT IN (123, 124, 125) OR cn.user_id = pnUserId)
       ))
       -- Personal SPECIFIC filters
       AND (cnm.channel_id > 0 OR cnm.collection_id > 0 OR n2025_notificationVipFilter(pnVip, cn.actor, cn.object_type, cn.action, pvUsername, cn.email))
   GROUP BY cn.id
   ORDER BY
       (CASE
          WHEN isnull(pnMinId) AND INSTR(vSort, "-") THEN
            CASE vFieldSort
              WHEN 'action_time' THEN cn.action_time               
              WHEN 'updated_date' THEN cn.updated_date
              WHEN 'created_date' THEN cn.created_date
            END
          WHEN NOT isnull(pnModifiedLT) THEN cn.updated_date
        END) DESC,
       (CASE
          WHEN NOT isnull(pnMinId) THEN cn.id
          WHEN NOT isnull(pnModifiedGTE) THEN cn.updated_date
          WHEN isnull(pnMinId) AND INSTR(vSort, "+") THEN
            CASE vFieldSort 
              WHEN 'action_time' THEN cn.action_time               
              WHEN 'updated_date' THEN cn.updated_date
              WHEN 'created_date' THEN cn.created_date
             END
        END) ASC
   LIMIT pnPageSize
  OFFSET nOFFSET;
  
END