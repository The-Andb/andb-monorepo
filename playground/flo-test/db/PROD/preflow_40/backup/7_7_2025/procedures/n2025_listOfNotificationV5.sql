CREATE PROCEDURE `n2025_listOfNotificationV5`(
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
  ,pvAction           VARCHAR(100)   -- OR
  ,pvAssignment       VARCHAR(20)    -- OR 0: ALL (DEFAULT) - 1: NOT Assigned - 2: Assigned TO Me - 3: Assigned BY Me
  ,pnIncludeShared    TINYINT(1)     -- != 1 - NOT GET shared kanban
  ,pnIncludeReaction  TINYINT(1)     -- 1: chat, 2: comment, 3: BOTH
  ,pnIncludePersonal  TINYINT(1)     -- != 1 - NOT GET personal notification
  ,pnActionByMe       TINYINT(1)
  ,pnUserId           BIGINT(20)
  ,pvUsername         VARCHAR(100)
  )
BEGIN
  -- only SHOW notification edited FOR mentioned member
  DECLARE nTimeToDel        DOUBLE;
  DECLARE vStatus           VARCHAR(20) DEFAULT ifnull(pvStatus, '0');
  DECLARE vAssignment       VARCHAR(20) DEFAULT ifnull(pvAssignment, '0'); 
  DECLARE nOFFSET           INT(11) DEFAULT 0;  
  DECLARE nLimit            INT(11) DEFAULT 5000;
  DECLARE nActionByMe       INT(11) DEFAULT ifnull(pnActionByMe, 0);
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
          SELECT cn.id, cn.collection_id, cn.channel_id, cn.`action`, cn.user_id, cn.content
                ,cn.object_type, cn.object_uid, cn.assignees, cn.email, cn.actor
                ,COALESCE(un.action_time, cn.action_time, 0) action_time, cn.comment_id, cn.created_date
                ,ifnull(un.updated_date, cn.updated_date) updated_date
                ,cn.kanban_id, cn.emoji_unicode
                ,co.calendar_uri owner_calendar_uri, co.user_id owner_user_id
                ,'' COLLATE utf8mb4_0900_ai_ci member_calendar_uri, '' COLLATE utf8mb4_0900_ai_ci member_email, 0 member_user_id
                ,usr.username owner_username, cn.account_id
                ,0 last_seen_chat
                ,0 last_seen_call
                ,cn.category
                ,un.has_mention
                ,ifnull(un.`status`, 0) `status`
                ,'t1' alias
            FROM collection_notification cn
       LEFT JOIN user_notification un ON (un.collection_notification_id = cn.id AND un.user_id = pnUserId)
            JOIN collection co ON cn.collection_id = co.id
            JOIN user usr ON (co.user_id = usr.id)
           WHERE cn.created_date >= nTimeToDel
             AND (pnCollectionId IS NULL OR co.id = pnCollectionId)
             AND (pnCollectionId IS NULL OR co.`type` = 3)  -- owner GET BY uid? dont need TO share
             AND co.user_id = pnUserId
             AND cn.channel_id = 0
             AND (isnull(pnMinId) OR cn.id > pnMinId)
             AND (isnull(pvObjectType) OR find_in_set(cn.object_type, pvObjectType))
             AND (isnull(pvIds) OR FIND_IN_SET(cn.id, pvIds))
             AND (cn.action NOT IN (31, 61) OR un.has_mention = 1)
             AND un.deleted_date IS NULL -- sprint 17.2 soft DELETE notification
             AND (pnCollectionId IS NULL OR cn.collection_id = pnCollectionId)
             AND (pnChannelId IS NULL OR cn.channel_id = pnChannelId)
            -- react comment. chat
             AND (cn.`action` NOT IN (23, 24) OR cn.user_id = pnUserId)
             -- modified
             AND n2025_notificationModifedFilter(un.id, cn.updated_date, un.updated_date, nModifiedLT, nModifiedGTE)
             --
             AND n2025_notificationActionFilter(pvAction, cn.action, un.has_mention)
             -- 0: ALL (DEFAULT) 
             AND n2025_notificationStatusFilter(vStatus, un.status, cn.created_date)
             -- 0: ALL (DEFAULT) 
             AND n2025_notificationAssignmentFilter(vAssignment, cn.object_type, cn.action, cn.assignees, pvUsername, cn.email) 
             -- <> 1 - NOT GET shared kanban
             AND (isnull(pnIncludeShared) OR cn.`action` NOT IN (20, 21, 22))
             -- pnIncludeReaction = 1: chat, 2: comment, 3: BOTH
             --  reaction chat
             AND IF(ifnull(pnIncludeReaction, 0) IN (1,3), 1, cn.`action` <> 23)
             -- reaction comment
             AND IF(ifnull(pnIncludeReaction, 0) IN (2,3), 1, cn.`action` <> 24)
             -- <> 1 - NOT GET personal notification: 23,24 for included reaction
             AND IF(ifnull(pnIncludePersonal, 0) = 1, 1, cn.`action` NOT IN (19, 30, 31, 70, 80, 81))
             -- action BY me
             AND NOT (nActionByMe = 1 AND actor_or_email <> pvUsername)
             -- 
             AND (
                 pvCategory IS NULL 
                 OR (
                     IF(cn.object_type <> 'VTODO'
                     ,1
                     ,FIND_IN_SET(cn.category, pvCategory))
                   )
                 )
             
UNION ALL -- member IN shared collection
          SELECT cn.id, cn.collection_id, cn.channel_id, cn.`action`, cn.user_id, cn.content
                ,cn.object_type, cn.object_uid, cn.assignees, cn.email, cn.actor
                ,COALESCE(un.action_time, cn.action_time, 0) action_time, cn.comment_id, cn.created_date
                ,ifnull(un.updated_date, cn.updated_date) updated_date
                ,cn.kanban_id, cn.emoji_unicode
                ,co.calendar_uri owner_calendar_uri, co.user_id owner_user_id
                ,csm.calendar_uri member_calendar_uri, csm.shared_email member_email, csm.member_user_id
                ,usr.username owner_username, cn.account_id
                ,0 last_seen_chat
                ,0 last_seen_call
                ,cn.category
                ,un.has_mention
                ,ifnull(un.`status`, 0) `status`
                ,'t2' alias
            FROM collection_notification cn
       LEFT JOIN user_notification un ON (un.collection_notification_id = cn.id AND un.user_id = pnUserId)
            JOIN collection co ON cn.collection_id = co.id
            JOIN user usr ON (co.user_id = usr.id)
            JOIN collection_shared_member csm ON (csm.collection_id = co.id AND csm.shared_status = 1)
           WHERE cn.created_date >= nTimeToDel
             AND (pnCollectionId IS NULL OR co.id = pnCollectionId)
             AND ifnull(co.is_trashed, 0) = 0
             AND csm.member_user_id = pnUserId
             AND cn.object_type <> 'CHAT'
             AND co.type = 3 -- share only
             -- only LOAD missed CALL notifications following the actions below:
             -- call_in_declined    = 123
             -- call_in_not_answer  = 124
             -- call_in_cancel      = 125
             AND (cn.action NOT IN (123, 124, 125) OR cn.user_id = pnUserId)
             AND (isnull(pnMinId) OR cn.id > pnMinId)
             AND (isnull(pvObjectType) OR find_in_set(cn.object_type, pvObjectType))
             AND (isnull(pvIds) OR FIND_IN_SET(cn.id, pvIds))
             AND (cn.action NOT IN (31, 61) OR un.has_mention = 1)
             AND un.deleted_date IS NULL -- sprint 17.2 soft DELETE notification
             AND (pnCollectionId IS NULL OR cn.collection_id = pnCollectionId)
             AND (pnChannelId IS NULL OR cn.channel_id = pnChannelId)
            -- react comment. chat
             AND (cn.`action` NOT IN (23, 24) OR cn.user_id = pnUserId)
             -- modified
             AND n2025_notificationModifedFilter(un.id,cn.updated_date, un.updated_date, nModifiedLT, nModifiedGTE)
             --
             AND n2025_notificationActionFilter(pvAction, cn.action, un.has_mention)
             -- 0: ALL (DEFAULT) 
             AND n2025_notificationStatusFilter(vStatus, un.status, cn.created_date)
              -- 0: ALL (DEFAULT) 
            AND n2025_notificationAssignmentFilter(vAssignment, cn.object_type, cn.action, cn.assignees, pvUsername, cn.email) 
             -- <> 1 - NOT GET shared kanban
             AND (isnull(pnIncludeShared) OR cn.`action` NOT IN (20, 21, 22))
             -- pnIncludeReaction = 1: chat, 2: comment, 3: BOTH
             --  reaction chat
             AND IF(ifnull(pnIncludeReaction, 0) IN (1,3), 1, cn.`action` <> 23)
             -- reaction comment
             AND IF(ifnull(pnIncludeReaction, 0) IN (2,3), 1, cn.`action` <> 24)
             -- <> 1 - NOT GET personal notification: 23,24 for included reaction
             AND IF(ifnull(pnIncludePersonal, 0) = 1, 1, cn.`action` NOT IN (19, 30, 31, 70, 80, 81))
             -- action BY me
             AND NOT (nActionByMe = 1 AND actor_or_email <> pvUsername)
             -- 
             AND (
                 pvCategory IS NULL 
                 OR (
                     IF(cn.object_type <> 'VTODO'
                     ,1
                     ,FIND_IN_SET(cn.category, pvCategory))
                   )
                 )
             
   UNION ALL -- conference
          SELECT cn.id, cn.collection_id, cn.channel_id, cn.`action`, cn.user_id, cn.content
                ,cn.object_type, cn.object_uid, cn.assignees, cn.email, cn.actor
                ,COALESCE(un.action_time, cn.action_time, 0) action_time, cn.comment_id, cn.created_date
                ,ifnull(un.updated_date, cn.updated_date) updated_date
                ,cn.kanban_id, cn.emoji_unicode
                ,'' COLLATE utf8mb4_0900_ai_ci owner_calendar_uri, '' COLLATE utf8mb4_0900_ai_ci owner_user_id, '' COLLATE utf8mb4_0900_ai_ci member_calendar_uri
                ,'' COLLATE utf8mb4_0900_ai_ci member_email, 0 member_user_id, '' COLLATE utf8mb4_0900_ai_ci owner_username, cn.account_id
                ,rculs.last_message_created_date last_seen_chat
                ,cm.last_seen_call
                ,cn.category
                ,un.has_mention
                ,n2025_notificationCallChatReadTransform(cn.object_type
                                                        ,un.`status`
                                                        ,rculs.last_message_created_date
                                                        ,cm.last_seen_call
                                                        ,cn.created_date
                                                        ,un.updated_date
                                                        ,cn.updated_date) AS `status`
                ,'t3' alias
            FROM collection_notification cn 
       LEFT JOIN user_notification un ON (un.collection_notification_id = cn.id AND un.user_id = pnUserId)
            JOIN conference_member cm ON (cn.channel_id = cm.channel_id)
            JOIN conference_channel cc ON (cc.id = cm.channel_id)
            JOIN `user` u ON (u.id = cm.user_id)
            JOIN realtime_channel rc ON (rc.type = 'CONFERENCE' AND cc.id = rc.internal_channel_id)
            JOIN realtime_channel_member rcm ON (rc.id = rcm.channel_id AND rcm.email = u.email)
            JOIN realtime_chat_channel_user_last_seen rculs ON (rculs.channel_id = rc.id AND rculs.email = u.email)
           WHERE cn.created_date >= nTimeToDel
             AND (pnChannelId IS NULL OR cc.id = pnChannelId)
             AND cm.user_id = pnUserId
             -- only LOAD missed CALL notifications following the actions below:
             -- call_in_declined    = 123
             -- call_in_not_answer  = 124
             -- call_in_cancel      = 125
             AND (cn.action NOT IN (123, 124, 125) OR cn.user_id = pnUserId)
             AND cc.is_trashed = 0
             AND cm.revoke_time = 0
             AND cn.created_date >= cm.join_time
             AND (isnull(pnMinId) OR cn.id > pnMinId)
             AND (isnull(pvObjectType) OR find_in_set(cn.object_type, pvObjectType))
             AND (isnull(pvIds) OR FIND_IN_SET(cn.id, pvIds))
             AND (cn.action NOT IN (31, 61) OR un.has_mention = 1)
             AND un.deleted_date IS NULL -- sprint 17.2 soft DELETE notification
             AND (pnCollectionId IS NULL OR cn.collection_id = pnCollectionId)
             AND (pnChannelId IS NULL OR cn.channel_id = pnChannelId)
            -- react comment. chat
             AND (cn.`action` NOT IN (23, 24) OR cn.user_id = pnUserId)
             -- modified
             AND n2025_notificationModifedFilter(un.id,cn.updated_date, un.updated_date, nModifiedLT, nModifiedGTE)
             --
             AND n2025_notificationActionFilter(pvAction, cn.action, un.has_mention)
             --         
             AND (
                 pvCategory IS NULL 
                 OR (
                     IF(cn.object_type <> 'VTODO'
                     ,1
                     ,FIND_IN_SET(cn.category, pvCategory))
                   )
                 )
             -- 0: ALL (DEFAULT) 
             AND (find_in_set(0, vStatus)
                OR (-- 1: New
                    IF(find_in_set(1, vStatus), unix_timestamp(now(3) - INTERVAL 1 day) <= cn.created_date, 1)
                    -- 2: READ
                    AND IF(find_in_set(2, vStatus)
                        ,n2025_notificationCallChatReadTransform(cn.object_type
                                                                ,un.`status`
                                                                ,rculs.last_message_created_date
                                                                ,cm.last_seen_call
                                                                ,cn.created_date
                                                                ,un.updated_date
                                                                ,cn.updated_date) = 1
                        ,1)
                    -- 3: Unread
                    AND IF(find_in_set(3, vStatus)
                        ,n2025_notificationCallChatReadTransform(cn.object_type
                                                                ,un.`status`
                                                                ,rculs.last_message_created_date
                                                                ,cm.last_seen_call
                                                                ,cn.created_date
                                                                ,un.updated_date
                                                                ,cn.updated_date) = 0
                        ,1)
                    -- 4: Closed
                    AND IF(find_in_set(4, vStatus), ifnull(un.status, 0) = 2, 1)
                  )
              )
             -- 0: ALL (DEFAULT) 
             AND n2025_notificationAssignmentFilter(vAssignment, cn.object_type, cn.action, cn.assignees, pvUsername, cn.email) 
             -- <> 1 - NOT GET shared kanban
             AND (isnull(pnIncludeShared) OR cn.`action` NOT IN (20, 21, 22))
             -- pnIncludeReaction = 1: chat, 2: comment, 3: BOTH
             --  reaction chat
             AND IF(ifnull(pnIncludeReaction, 0) IN (1,3), 1, cn.`action` <> 23)
             -- reaction comment
             AND IF(ifnull(pnIncludeReaction, 0) IN (2,3), 1, cn.`action` <> 24)
             -- <> 1 - NOT GET personal notification: 23,24 for included reaction
             AND IF(ifnull(pnIncludePersonal, 0) = 1, 1, cn.`action` NOT IN (19, 30, 31, 70, 80, 81))
             -- action BY me
             AND NOT (nActionByMe = 1 AND actor_or_email <> pvUsername)
             
     UNION ALL -- user notifications
          SELECT cn.id, cn.collection_id, cn.channel_id, cn.`action`, cn.user_id, cn.content
                 ,cn.object_type, cn.object_uid, cn.assignees, cn.email, cn.actor
                 ,COALESCE(un.action_time, cn.action_time, 0) action_time, cn.comment_id, cn.created_date
                 ,ifnull(un.updated_date, cn.updated_date) updated_date
                 ,cn.kanban_id, cn.emoji_unicode
                 ,'' COLLATE utf8mb4_0900_ai_ci owner_calendar_uri, '' COLLATE utf8mb4_0900_ai_ci owner_user_id, '' COLLATE utf8mb4_0900_ai_ci member_calendar_uri
                 ,'' COLLATE utf8mb4_0900_ai_ci member_email, 0 member_user_id, '' COLLATE utf8mb4_0900_ai_ci owner_username, cn.account_id
                 ,0 last_seen_chat
                 ,0 last_seen_call
                 ,cn.category
                 ,un.has_mention
                 ,ifnull(un.`status`, 0) `status`
                 ,'t4' alias
             FROM collection_notification cn
        LEFT JOIN user_notification un ON (un.collection_notification_id = cn.id AND un.user_id = pnUserId)
            WHERE cn.created_date >= nTimeToDel
              AND pnCollectionId IS NULL
              AND pnChannelId IS NULL
              AND cn.user_id = pnUserId
              AND cn.collection_id = 0
              AND cn.channel_id = 0
              AND ifnull(pnCollectionId, 0) = 0
              AND ifnull(pnChannelId, 0) = 0
              AND (isnull(pnMinId) OR cn.id > pnMinId)
              AND (isnull(pvObjectType) OR find_in_set(cn.object_type, pvObjectType))
              AND (isnull(pvIds) OR FIND_IN_SET(cn.id, pvIds))
              AND (cn.action NOT IN (31, 61) OR un.has_mention = 1)
              AND un.deleted_date IS NULL -- sprint 17.2 soft DELETE notification
              AND (pnCollectionId IS NULL OR cn.collection_id = pnCollectionId)
              AND (pnChannelId IS NULL OR cn.channel_id = pnChannelId)
             -- react comment. chat
              AND (cn.`action` NOT IN (23, 24) OR cn.user_id = pnUserId)
              -- modified
              AND n2025_notificationModifedFilter(un.id,cn.updated_date, un.updated_date, nModifiedLT, nModifiedGTE)
              --
              AND n2025_notificationActionFilter(pvAction, cn.action, un.has_mention)
              -- 0: ALL (DEFAULT) 
               AND n2025_notificationStatusFilter(vStatus, un.status, cn.created_date)
              -- 0: ALL (DEFAULT) 
              AND n2025_notificationAssignmentFilter(vAssignment, cn.object_type, cn.action, cn.assignees, pvUsername, cn.email) 
              -- <> 1 - NOT GET shared kanban
              AND (isnull(pnIncludeShared) OR cn.`action` NOT IN (20, 21, 22))
              -- pnIncludeReaction = 1: chat, 2: comment, 3: BOTH
              --  reaction chat
              AND IF(ifnull(pnIncludeReaction, 0) IN (1,3), 1, cn.`action` <> 23)
              -- reaction comment
              AND IF(ifnull(pnIncludeReaction, 0) IN (2,3), 1, cn.`action` <> 24)
              -- <> 1 - NOT GET personal notification: 23,24 for included reaction
              AND IF(ifnull(pnIncludePersonal, 0) = 1, 1, cn.`action` NOT IN (19, 30, 31, 70, 80, 81))
              -- action BY me
              AND NOT (nActionByMe = 1 AND actor_or_email <> pvUsername)
              
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
--          ,cn.alias
--          ,cn.last_seen_call
--          ,cn.last_seen_chat
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