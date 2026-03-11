CREATE PROCEDURE `n2025_listOfNotificationV4`(
   pnCollectionId     BIGINT(20)
  ,pnChannelId        BIGINT(20)
  ,pnUserId           BIGINT(20)
  ,pvUsername         VARCHAR(100)
  ,pvIds              TEXT
  ,pnModifiedGTE      DOUBLE(14,4)
  ,pnModifiedLT       DOUBLE(14,4)
  ,pnMinId            BIGINT(20)
  ,pnPageSize         INTEGER(11)
  ,pnPageNo           INTEGER(11)
  ,pvSort             VARCHAR(128)
  ,pvStatus           VARCHAR(20)    -- AND 0: ALL (DEFAULT) - 1: New - 2: READ - 3: Unread
  ,pvObjectType       VARBINARY(250) -- OR VEVENT, VTODO, VJOURNAL, URL, CHAT, COMMENT,..
  ,pvAction           VARCHAR(100)   -- OR
  ,pvAssignment       VARCHAR(20)    -- OR 0: ALL (DEFAULT) - 1: NOT Assigned - 2: Assigned TO Me - 3: Assigned BY Me
  ,pnIncludeShared    TINYINT(1)     -- != 1 - NOT GET shared kanban
  ,pnIncludeReaction  TINYINT(1)     -- 1: chat, 2: comment, 3: BOTH
  ,pnIncludePersonal  TINYINT(1)     -- != 1 - NOT GET personal notification
  )
BEGIN
  -- only SHOW notification edited FOR mentioned member
  DECLARE nTimeToDel        DOUBLE;
  DECLARE vStatus           VARCHAR(20) DEFAULT ifnull(pvStatus, '0');
  DECLARE vAssignment       VARCHAR(20) DEFAULT ifnull(pvAssignment, '0'); 
  DECLARE nOFFSET           INT(11) DEFAULT 0;  
  DECLARE nLimit            INT(11) DEFAULT 5000;
  DECLARE vFieldSort        VARCHAR(50) DEFAULT REPLACE(REPLACE(IFNULL(pvSort, ''), '-', ''), '+', '');                                              
  DECLARE vSort             VARCHAR(50) DEFAULT IF(IFNULL(pvSort, '') <> '' -- DEFAULT +: ASC
                                                  AND NOT instr(pvSort, '-') 
                                                  AND NOT instr(pvSort, '+')
                                                 ,concat('+', pvSort), pvSort);
                                                 
  DECLARE nModifiedLT DOUBLE(14,4) DEFAULT IF(ifnull(pnModifiedLT, 0) > 0, pnModifiedLT, unix_timestamp() + 1);
  DECLARE nModifiedGTE DOUBLE(14,4) DEFAULT IF(ifnull(pnModifiedGTE, 0) > 0, pnModifiedGTE, 0);
  --
  IF ifnull(pvSort, 'NA') <> 'NA' THEN
    --
    SET nOFFSET = IF(ifnull(pnPageNo, 0) = 0, 0, (pnPageNo - 1) * pnPageSize);
    --
  END IF;
  --
  SET nTimeToDel = n2025_getMinCreatedDateToShowNotification(pnUserId);
  --
  WITH notifications AS (
          -- owner existed collection_id
          SELECT cn1.id, cn1.collection_id, cn1.channel_id, cn1.`action`, cn1.user_id, cn1.content
                ,cn1.object_type, cn1.object_uid, cn1.assignees, cn1.email, cn1.actor
                ,COALESCE(un.action_time, cn1.action_time, 0) action_time, cn1.comment_id, cn1.created_date
                ,greatest(cn1.updated_date, ifnull(un.updated_date, 0)) updated_date
                ,cn1.kanban_id, cn1.emoji_unicode
                ,co.calendar_uri owner_calendar_uri, co.user_id owner_user_id
                ,'' COLLATE utf8mb4_0900_ai_ci member_calendar_uri, '' COLLATE utf8mb4_0900_ai_ci member_email, 0 member_user_id
                ,usr.username owner_username, cn1.account_id
                ,0 last_seen_chat
                ,0 last_seen_call
                ,cn1.category
                ,un.has_mention
                ,ifnull(un.`status`, 0) `status`
                ,'t1' alias
            FROM collection co
            JOIN user usr ON (co.user_id = usr.id)
            JOIN collection_notification cn1 ON cn1.collection_id = co.id
       LEFT JOIN user_notification un ON (un.collection_notification_id = cn1.id AND un.user_id = pnUserId)
           WHERE cn1.created_date >= nTimeToDel
             AND co.user_id = pnUserId
             AND (pnCollectionId IS NULL OR co.id = pnCollectionId)
             AND (pnCollectionId IS NULL OR co.`type` = 3)  -- owner GET BY uid? dont need TO share
             AND cn1.channel_id = 0
             AND cn1.id > IF(ifnull(pnMinId, 0) > 0, pnMinId, 0)
             AND IF(isnull(pvObjectType), 1, find_in_set(cn1.object_type, pvObjectType))
             AND IF(ifnull(pvIds,'NA') <> 'NA', FIND_IN_SET(cn1.id, pvIds), 1)
             AND IF(cn1.action IN (31, 61), un.has_mention = 1, 1)
             AND un.deleted_date IS NULL -- sprint 17.2 soft DELETE notification
             AND (pnCollectionId IS NULL OR cn1.collection_id = pnCollectionId)
             AND (pnChannelId IS NULL OR cn1.channel_id = pnChannelId)
             AND IF(cn1.`action` IN (23, 24), cn1.user_id = pnUserId, 1)
             
             AND IF (un.id IS NOT NULL
                     ,greatest(cn1.updated_date, un.updated_date) < nModifiedLT
                     ,cn1.updated_date < nModifiedLT)
                     
             AND IF (un.id IS NOT NULL
                   ,greatest(cn1.updated_date, un.updated_date) >= nModifiedGTE
                   ,cn1.updated_date >= nModifiedGTE)
             
             AND n2025_notificationActionFilter(pvAction, cn1.action, un.has_mention)
             -- 0: ALL (DEFAULT) 
             AND n2025_notificationStatusFilter(vStatus, un.status, cn1.created_date)
             -- 0: ALL (DEFAULT) 
             AND n2025_notificationAssignmentFilter(vAssignment, cn1.object_type, cn1.action, cn1.assignees, pvUsername, cn1.email) 
             -- <> 1 - NOT GET shared kanban
             AND IF(ifnull(pnIncludeShared, 0) = 1, 1, cn1.`action` NOT IN (20, 21, 22))
             -- pnIncludeReaction = 1: chat, 2: comment, 3: BOTH
             --  reaction chat
             AND IF(ifnull(pnIncludeReaction, 0) IN (1,3), 1, cn1.`action` <> 23)
             -- reaction comment
             AND IF(ifnull(pnIncludeReaction, 0) IN (2,3), 1, cn1.`action` <> 24)
             -- <> 1 - NOT GET personal notification: 23,24 for included reaction
             AND IF(ifnull(pnIncludePersonal, 0) = 1, 1, cn1.`action` NOT IN (19, 30, 31, 70, 80, 81))
 
UNION ALL
          SELECT cn2.id, cn2.collection_id, cn2.channel_id, cn2.`action`, cn2.user_id, cn2.content
                ,cn2.object_type, cn2.object_uid, cn2.assignees, cn2.email, cn2.actor
                ,COALESCE(un.action_time, cn2.action_time, 0) action_time, cn2.comment_id, cn2.created_date
                ,greatest(cn2.updated_date, ifnull(un.updated_date, 0)) updated_date
                ,cn2.kanban_id, cn2.emoji_unicode
                ,co.calendar_uri owner_calendar_uri, co.user_id owner_user_id
                ,csm.calendar_uri member_calendar_uri, csm.shared_email member_email, csm.member_user_id
                ,usr.username owner_username, cn2.account_id
                ,0 last_seen_chat
                ,0 last_seen_call
                ,cn2.category
                ,un.has_mention
                ,ifnull(un.`status`, 0) `status`
                ,'t2' alias
            FROM collection co
            JOIN user usr ON (co.user_id = usr.id)
            JOIN collection_notification cn2 ON cn2.collection_id = co.id
       LEFT JOIN user_notification un ON (un.collection_notification_id = cn2.id AND un.user_id = pnUserId)
            JOIN collection_shared_member csm ON (csm.collection_id = co.id AND csm.shared_status = 1)
           WHERE cn2.created_date >= nTimeToDel
             AND (pnCollectionId IS NULL OR co.id = pnCollectionId)
             AND ifnull(co.is_trashed, 0) = 0
             AND csm.member_user_id = pnUserId
             AND cn2.object_type <> 'CHAT'
             AND co.type = 3 -- share only
             -- only LOAD missed CALL notifications following the actions below:
             -- call_in_declined    = 123
             -- call_in_not_answer  = 124
             -- call_in_cancel      = 125
             AND (cn2.action NOT IN (123, 124, 125) OR cn2.user_id = pnUserId)
             AND cn2.id > IF(ifnull(pnMinId, 0) > 0, pnMinId, 0)
             AND IF(isnull(pvObjectType), 1, find_in_set(cn2.object_type, pvObjectType))
             AND IF(ifnull(pvIds,'NA') <> 'NA', FIND_IN_SET(cn2.id, pvIds), 1)
             AND IF(cn2.action IN (31, 61), un.has_mention = 1, 1)
             AND un.deleted_date IS NULL -- sprint 17.2 soft DELETE notification
             AND (pnCollectionId IS NULL OR cn2.collection_id = pnCollectionId)
             AND (pnChannelId IS NULL OR cn2.channel_id = pnChannelId)
             AND IF(cn2.`action` IN (23, 24), cn2.user_id = pnUserId, 1)
             
             AND IF (un.id IS NOT NULL
                     ,greatest(cn2.updated_date, un.updated_date) < nModifiedLT
                     ,cn2.updated_date < nModifiedLT)
                     
             AND IF (un.id IS NOT NULL
                   ,greatest(cn2.updated_date, un.updated_date) >= nModifiedGTE
                   ,cn2.updated_date >= nModifiedGTE)
                   
             AND n2025_notificationActionFilter(pvAction, cn2.action, un.has_mention)
             -- 0: ALL (DEFAULT) 
             AND n2025_notificationStatusFilter(vStatus, un.status, cn2.created_date)
              -- 0: ALL (DEFAULT) 
            AND n2025_notificationAssignmentFilter(vAssignment, cn2.object_type, cn2.action, cn2.assignees, pvUsername, cn2.email) 
             -- <> 1 - NOT GET shared kanban
             AND IF(ifnull(pnIncludeShared, 0) = 1, 1, cn2.`action` NOT IN (20, 21, 22))
             -- pnIncludeReaction = 1: chat, 2: comment, 3: BOTH
             --  reaction chat
             AND IF(ifnull(pnIncludeReaction, 0) IN (1,3), 1, cn2.`action` <> 23)
             -- reaction comment
             AND IF(ifnull(pnIncludeReaction, 0) IN (2,3), 1, cn2.`action` <> 24)
             -- <> 1 - NOT GET personal notification: 23,24 for included reaction
             AND IF(ifnull(pnIncludePersonal, 0) = 1, 1, cn2.`action` NOT IN (19, 30, 31, 70, 80, 81))
   UNION ALL
          SELECT cn3.id, cn3.collection_id, cn3.channel_id, cn3.`action`, cn3.user_id, cn3.content
                ,cn3.object_type, cn3.object_uid, cn3.assignees, cn3.email, cn3.actor
                ,COALESCE(un.action_time, cn3.action_time, 0) action_time, cn3.comment_id, cn3.created_date
                ,greatest(cn3.updated_date, ifnull(un.updated_date, 0)) updated_date
                ,cn3.kanban_id, cn3.emoji_unicode
                ,'' COLLATE utf8mb4_0900_ai_ci owner_calendar_uri, '' COLLATE utf8mb4_0900_ai_ci owner_user_id, '' COLLATE utf8mb4_0900_ai_ci member_calendar_uri
                ,'' COLLATE utf8mb4_0900_ai_ci member_email, 0 member_user_id, '' COLLATE utf8mb4_0900_ai_ci owner_username, cn3.account_id
                ,rculs.last_message_created_date last_seen_chat
                ,cm.last_seen_call
                ,cn3.category
                ,un.has_mention
                ,CASE 
                    WHEN cn3.object_type = 'CHAT'
                          AND IFNULL(un.`status`, 0) = 0 
                          AND IFNULL(rculs.last_message_created_date, 0) > 0
                          AND rculs.last_message_created_date >= GREATEST(cn3.created_date, ifnull(un.updated_date, cn3.updated_date))
                    THEN 1
                      WHEN cn3.object_type = 'CALL'
                          AND IFNULL(un.`status`, 0) = 0 
                          AND IFNULL(cm.last_seen_call, 0) > 0
                          AND cm.last_seen_call >= GREATEST(cn3.created_date, ifnull(un.updated_date, cn3.updated_date))
                    THEN 1
                    ELSE ifnull(un.`status`, 0)
                  END `status`
                ,'t3' alias
            FROM conference_channel cc
            JOIN conference_member cm  ON (cc.id = cm.channel_id)
            JOIN `user` u ON (u.id = cm.user_id)
            JOIN collection_notification cn3 ON (cn3.channel_id = cm.channel_id)
       LEFT JOIN user_notification un ON (un.collection_notification_id = cn3.id AND un.user_id = pnUserId)
            JOIN realtime_channel rc ON (rc.type = 'CONFERENCE' AND cc.id = rc.internal_channel_id)
            JOIN realtime_channel_member rcm ON (rc.id = rcm.channel_id AND rcm.email = u.email)
            JOIN realtime_chat_channel_user_last_seen rculs ON (rculs.channel_id = rc.id AND rculs.email = u.email)
           WHERE cn3.created_date >= nTimeToDel
             AND (pnChannelId IS NULL OR cc.id = pnChannelId)
             AND cm.user_id = pnUserId
             -- only LOAD missed CALL notifications following the actions below:
             -- call_in_declined    = 123
             -- call_in_not_answer  = 124
             -- call_in_cancel      = 125
             AND (cn3.action NOT IN (123, 124, 125) OR cn3.user_id = pnUserId)
             AND cc.is_trashed = 0
             AND cm.revoke_time = 0
             AND cn3.created_date >= cm.join_time
             AND cn3.id > IF(ifnull(pnMinId, 0) > 0, pnMinId, 0)
             AND IF(isnull(pvObjectType), 1, find_in_set(cn3.object_type, pvObjectType))
             AND IF(ifnull(pvIds,'NA') <> 'NA', FIND_IN_SET(cn3.id, pvIds), 1)
             AND IF(cn3.action IN (31, 61), un.has_mention = 1, 1)
             AND un.deleted_date IS NULL -- sprint 17.2 soft DELETE notification
             AND (pnCollectionId IS NULL OR cn3.collection_id = pnCollectionId)
             AND (pnChannelId IS NULL OR cn3.channel_id = pnChannelId)
             AND IF(cn3.`action` IN (23, 24), cn3.user_id = pnUserId, 1)
             
             AND IF (un.id IS NOT NULL
                     ,greatest(cn3.updated_date, un.updated_date) < nModifiedLT
                     ,cn3.updated_date < nModifiedLT)
                     
             AND IF (un.id IS NOT NULL
                   ,greatest(cn3.updated_date, un.updated_date) >= nModifiedGTE
                   ,cn3.updated_date >= nModifiedGTE)
                    
             AND n2025_notificationActionFilter(pvAction, cn3.action, un.has_mention)
             -- 0: ALL (DEFAULT) 
             AND (find_in_set(0, vStatus)
                OR (-- 1: New
                    IF(find_in_set(1, vStatus), unix_timestamp(now(3) - INTERVAL 1 day) <= cn3.created_date, 1)
                    -- 2: READ
                    AND IF(find_in_set(2, vStatus)
                          ,(CASE 
                              WHEN IFNULL(un.`status`, 0) = 0 
                                    AND IFNULL(rculs.last_message_created_date, 0) > 0
                                    AND rculs.last_message_created_date >= GREATEST(cn3.created_date, ifnull(un.updated_date, cn3.updated_date))
                              THEN 1
                              ELSE un.`status`
                            END) = 1, 1)
                    -- 3: Unread
                    AND IF(find_in_set(3, vStatus)
                          ,(CASE 
                              WHEN IFNULL(un.`status`, 0) = 0 
                                    AND IFNULL(rculs.last_message_created_date, 0) > 0
                                    AND rculs.last_message_created_date >= GREATEST(cn3.created_date, ifnull(un.updated_date, cn3.updated_date))
                              THEN 1
                              ELSE un.`status`
                            END) = 0, 1)
                    -- 4: Closed
                    AND IF(find_in_set(4, vStatus), ifnull(un.status, 0) = 2, 1)
                  )
              )
             -- 0: ALL (DEFAULT) 
             AND n2025_notificationAssignmentFilter(vAssignment, cn3.object_type, cn3.action, cn3.assignees, pvUsername, cn3.email) 
             -- <> 1 - NOT GET shared kanban
             AND IF(ifnull(pnIncludeShared, 0) = 1, 1, cn3.`action` NOT IN (20, 21, 22))
             -- pnIncludeReaction = 1: chat, 2: comment, 3: BOTH
             --  reaction chat
             AND IF(ifnull(pnIncludeReaction, 0) IN (1,3), 1, cn3.`action` <> 23)
             -- reaction comment
             AND IF(ifnull(pnIncludeReaction, 0) IN (2,3), 1, cn3.`action` <> 24)
             -- <> 1 - NOT GET personal notification: 23,24 for included reaction
             AND IF(ifnull(pnIncludePersonal, 0) = 1, 1, cn3.`action` NOT IN (19, 30, 31, 70, 80, 81))
     UNION ALL
          SELECT cn4.id, cn4.collection_id, cn4.channel_id, cn4.`action`, cn4.user_id, cn4.content
                 ,cn4.object_type, cn4.object_uid, cn4.assignees, cn4.email, cn4.actor
                 ,COALESCE(un.action_time, cn4.action_time, 0) action_time, cn4.comment_id, cn4.created_date
                 ,greatest(cn4.updated_date, ifnull(un.updated_date, 0)) updated_date
                 ,cn4.kanban_id, cn4.emoji_unicode
                 ,'' COLLATE utf8mb4_0900_ai_ci owner_calendar_uri, '' COLLATE utf8mb4_0900_ai_ci owner_user_id, '' COLLATE utf8mb4_0900_ai_ci member_calendar_uri
                 ,'' COLLATE utf8mb4_0900_ai_ci member_email, 0 member_user_id, '' COLLATE utf8mb4_0900_ai_ci owner_username, cn4.account_id
                 ,0 last_seen_chat
                 ,0 last_seen_call
                 ,cn4.category
                 ,un.has_mention
                 ,ifnull(un.`status`, 0) `status`
                 ,'t4' alias
             FROM collection_notification cn4
          LEFT JOIN user_notification un ON (un.collection_notification_id = cn4.id AND un.user_id = pnUserId)
            WHERE cn4.created_date >= nTimeToDel
              AND cn4.user_id = pnUserId
              AND cn4.collection_id = 0
              AND cn4.channel_id = 0
              AND ifnull(pnCollectionId, 0) = 0
              AND ifnull(pnChannelId, 0) = 0
              AND cn4.id > IF(ifnull(pnMinId, 0) > 0, pnMinId, 0)
              AND IF(isnull(pvObjectType), 1, find_in_set(cn4.object_type, pvObjectType))
              AND IF(ifnull(pvIds,'NA') <> 'NA', FIND_IN_SET(cn4.id, pvIds), 1)
              AND IF(cn4.action IN (31, 61), un.has_mention = 1, 1)
              AND un.deleted_date IS NULL -- sprint 17.2 soft DELETE notification
              AND (pnCollectionId IS NULL OR cn4.collection_id = pnCollectionId)
              AND (pnChannelId IS NULL OR cn4.channel_id = pnChannelId)
              AND IF(cn4.`action` IN (23, 24), cn4.user_id = pnUserId, 1)
              AND IF (un.id IS NOT NULL
                     ,un.updated_date < nModifiedLT
                     ,cn4.updated_date < nModifiedLT)
             AND IF (un.id IS NOT NULL
                   ,un.updated_date >= nModifiedGTE
                   ,cn4.updated_date >= nModifiedGTE)
              AND n2025_notificationActionFilter(pvAction, cn4.action, un.has_mention)
              -- 0: ALL (DEFAULT) 
               AND n2025_notificationStatusFilter(vStatus, un.status, cn4.created_date)
              -- 0: ALL (DEFAULT) 
              AND n2025_notificationAssignmentFilter(vAssignment, cn4.object_type, cn4.action, cn4.assignees, pvUsername, cn4.email) 
              -- <> 1 - NOT GET shared kanban
              AND IF(ifnull(pnIncludeShared, 0) = 1, 1, cn4.`action` NOT IN (20, 21, 22))
              -- pnIncludeReaction = 1: chat, 2: comment, 3: BOTH
              --  reaction chat
            AND IF(ifnull(pnIncludeReaction, 0) IN (1,3), 1, cn4.`action` <> 23)
            -- reaction comment
            AND IF(ifnull(pnIncludeReaction, 0) IN (2,3), 1, cn4.`action` <> 24)
            -- <> 1 - NOT GET personal notification: 23,24 for included reaction
            AND IF(ifnull(pnIncludePersonal, 0) = 1, 1, cn4.`action` NOT IN (19, 30, 31, 70, 80, 81))
  )
  --
  SELECT cn.id, ifnull(cn.actor, cn.email) email, cn.collection_id, ifnull(cn.channel_id, 0) channel_id
        ,cn.object_uid, cn.object_type
        ,CASE
            WHEN cn.`action` IN (6, 61) AND cn.has_mention = 1
            THEN 63 -- VIRTUAL action: 63 - MENTIONED COMMENT
            WHEN cn.`action` IN (30, 31) AND cn.has_mention = 1
            THEN 33 -- VIRTUAL action: 33 - MENTIONED CHAT
            ELSE cn.action
         END `action`
        ,cn.content, cn.action_time, cn.comment_id
        ,cn.created_date , cn.updated_date
        ,cn.member_calendar_uri, cn.member_email, cn.member_user_id
        ,cn.owner_user_id, cn.owner_calendar_uri, cn.owner_username, cn.owner_user_id, cn.account_id
        ,cn.status , cn.kanban_id, cn.assignees, ifnull(cn.emoji_unicode, '') emoji_unicode, cn.account_id, cn.category
        ,IF(cn.object_type NOT IN ('VEVENT', 'VJOURNAL', 'VTODO') 
             ,''
             ,concat("/calendarserver.php/calendars/"
               ,cn.owner_username, "/"
               ,cn.owner_calendar_uri, "/"
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
          -- ,cn.alias
     FROM notifications cn
    GROUP BY cn.id
    ORDER BY
        (CASE
           --
           WHEN isnull(pnMinId) AND INSTR(vSort, "-") THEN
             --
             CASE vFieldSort
               --
               WHEN 'action_time' THEN cn.action_time               
               WHEN 'updated_date' THEN cn.updated_date
               WHEN 'created_date' THEN cn.created_date
               --
             END
           WHEN NOT isnull(pnModifiedLT) THEN cn.updated_date
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