CREATE FUNCTION `n2025_getTotalUnreadNotification`(
 pnCollectionId     BIGINT(20)
,pnChannelId        BIGINT(20)
,pnUserId           BIGINT(20)
,pvUsername         VARCHAR(100)
,pvStatus           VARCHAR(20)    -- AND 0: ALL (DEFAULT) - 1: New - 2: READ - 3: Unread
,pvObjectType       VARBINARY(250) -- OR VEVENT, VTODO, VJOURNAL, URL
,pvAction           VARCHAR(100)   -- OR
,pvAssignment       VARCHAR(20)    -- OR 0: ALL (DEFAULT) - 1: NOT Assigned - 2: Assigned TO Me - 3: Assigned BY Me
,pnIncludeShared    TINYINT(1)
,pnIncludeReaction  TINYINT(1)     -- 1: chat, 2: comment, 3: BOTH
,pnIncludePersonal  TINYINT(1)
) RETURNS INT
BEGIN
  -- this fn TO GET total at API GET notification list
  DECLARE vStatus           VARCHAR(20) DEFAULT ifnull(pvStatus, '0');
  DECLARE vAssignment       VARCHAR(20) DEFAULT ifnull(pvAssignment, '0');
  DECLARE nReturn           INT(11) DEFAULT 0;
  --
  SELECT count(cn.id)
     INTO nReturn
     FROM (          -- owner existed collection_id
          SELECT t1.id, t1.collection_id, t1.channel_id, t1.`action`, t1.user_id, t1.content
                ,t1.object_type, t1.object_uid, t1.assignees, t1.email, t1.actor
                ,t1.action_time, t1.comment_id, t1.created_date, t1.updated_date
                ,t1.kanban_id, t1.emoji_unicode
                ,t1.owner_calendar_uri, t1.owner_user_id
                ,t1.member_calendar_uri, t1.member_email, t1.member_user_id
                ,t1.owner_username, t1.account_id
                ,t1.last_seen_chat, t1.last_seen_call, t1.category
                ,t1.has_mention
                ,t1.status
            FROM (SELECT cn.id, cn.collection_id, cn.channel_id, cn.`action`, cn.user_id, cn.content
                        ,cn.object_type, cn.object_uid, cn.assignees, cn.email, cn.actor
                        ,COALESCE(un.action_time, cn.action_time, 0) action_time, cn.comment_id, cn.created_date, greatest(cn.updated_date, ifnull(un.updated_date, 0)) updated_date
                        ,cn.kanban_id, cn.emoji_unicode
                        ,co.calendar_uri owner_calendar_uri, co.user_id owner_user_id
                        ,'' COLLATE utf8mb4_0900_ai_ci member_calendar_uri, '' COLLATE utf8mb4_0900_ai_ci member_email, 0 member_user_id
                        ,usr.username owner_username, cn.account_id
                        ,0 last_seen_chat
                        ,0 last_seen_call
                        ,cn.category
                        ,un.has_mention
                        ,ifnull(un.`status`, 0) `status`
                    FROM collection_notification cn
               LEFT JOIN user_notification un ON (un.collection_notification_id = cn.id AND un.user_id = pnUserId)
                    JOIN collection co ON cn.collection_id = co.id
                    JOIN user usr ON (co.user_id = usr.id)
                   WHERE (pnCollectionId IS NULL OR co.id = pnCollectionId)
                     AND (pnCollectionId IS NULL OR co.`type` = 3)  -- owner GET BY uid? dont need TO share
                     AND co.user_id = pnUserId
                     AND cn.channel_id = 0
                     AND IF(isnull(pvObjectType), 1, find_in_set(cn.object_type, pvObjectType))
                     
                     AND IF(cn.action IN (31, 61), un.has_mention = 1, 1)
                     AND un.deleted_date IS NULL -- sprint 17.2 soft DELETE notification
                     AND (pnCollectionId IS NULL OR cn.collection_id = pnCollectionId)
                     AND (pnChannelId IS NULL OR cn.channel_id = pnChannelId)
                     AND IF(cn.`action` IN (23, 24), cn.user_id = pnUserId, 1)
                     AND IF(isnull(pvAction), 1,
                           (-- find exactly action
                             find_in_set(cn.`action`, pvAction)
                             -- for comment
                             OR CASE 
                               WHEN find_in_set(6, pvAction)
                               THEN (cn.action = 61 AND un.has_mention = 1) OR find_in_set(cn.`action`, pvAction)
                               WHEN find_in_set(63, pvAction)
                               THEN un.has_mention = 1 AND cn.action IN (6, 61)
                             END 
                             -- for chat
                           OR CASE 
                               WHEN find_in_set(30, pvAction)
                               THEN (cn.action = 31 AND un.has_mention = 1) OR find_in_set(cn.`action`, pvAction)
                               WHEN find_in_set(33, pvAction)
                               THEN un.has_mention = 1 AND cn.action IN (30, 31)
                             END
                           )
                         )
                     -- 0: ALL (DEFAULT) 
                     AND (find_in_set(0, vStatus)
                         OR (-- 1: New
                             IF(find_in_set(1, vStatus), unix_timestamp(now(3) - INTERVAL 1 day) <= cn.created_date, 1)
                             -- 2: READ
                             AND IF(find_in_set(2, vStatus), un.`status` = 1, 1)
                             -- 3: Unread
                             AND IF(find_in_set(3, vStatus), un.`status` = 0, 1)
                             -- 4: Closed
                             AND IF(find_in_set(4, vStatus), ifnull(un.status, 0) = 2, 1)
                           )
                       )
                     -- 0: ALL (DEFAULT) 
                     AND (find_in_set(0, vAssignment)
                         OR (
                         cn.object_type = 'VTODO' AND (
                         -- 4: ALL VTODO
                             find_in_set(4, vAssignment)
                         -- 1: NOT Assigned
                         OR (find_in_set(1, vAssignment) AND (ifnull(cn.assignees, '') = '' OR cn.action = 18)) -- 18 >> Un-Assigned 
                         -- 2: Assigned TO Me 
                         OR (find_in_set(2, vAssignment) AND cn.action = 17 AND find_in_set(pvUsername, ifnull(cn.assignees, 'NA')))
                         -- 3: Assigned BY Me
                         OR (find_in_set(3, vAssignment) AND cn.email = pvUsername AND cn.action = 17)
                         )
                       )
                     )
                     -- <> 1 - NOT GET shared kanban
                     AND IF(ifnull(pnIncludeShared, 0) = 1, 1, cn.`action` NOT IN (20, 21, 22))
                     -- pnIncludeReaction = 1: chat, 2: comment, 3: BOTH
                     --  reaction chat
                   AND IF(ifnull(pnIncludeReaction, 0) IN (1,3), 1, cn.`action` <> 23)
                   -- reaction comment
                   AND IF(ifnull(pnIncludeReaction, 0) IN (2,3), 1, cn.`action` <> 24)
                   -- <> 1 - NOT GET personal notification: 23,24 for included reaction
                   AND IF(ifnull(pnIncludePersonal, 0) = 1, 1, cn.`action` NOT IN (19, 30, 31, 70, 80, 81))
                    LIMIT 1100
             ) t1
           UNION -- member existed collection_id
          SELECT t2.id, t2.collection_id, t2.channel_id, t2.`action`, t2.user_id, t2.content
                ,t2.object_type, t2.object_uid, t2.assignees, t2.email, t2.actor
                ,t2.action_time, t2.comment_id, t2.created_date, t2.updated_date
                ,t2.kanban_id, t2.emoji_unicode
                ,t2.owner_calendar_uri, t2.owner_user_id
                ,t2.member_calendar_uri, t2.member_email, t2.member_user_id
                ,t2.owner_username, t2.account_id
                ,t2.last_seen_chat, t2.last_seen_call, t2.category
                ,t2.has_mention
                ,t2.status
            FROM (SELECT cn.id, cn.collection_id, cn.channel_id, cn.`action`, cn.user_id, cn.content
                        ,cn.object_type, cn.object_uid, cn.assignees, cn.email, cn.actor
                        ,COALESCE(un.action_time, cn.action_time, 0) action_time, cn.comment_id, cn.created_date, greatest(cn.updated_date, ifnull(un.updated_date, 0)) updated_date
                        ,cn.kanban_id, cn.emoji_unicode
                        ,co.calendar_uri owner_calendar_uri, co.user_id owner_user_id
                        ,csm.calendar_uri member_calendar_uri, csm.shared_email member_email, csm.member_user_id
                        ,usr.username owner_username, cn.account_id
                        ,0 last_seen_chat
                        ,0 last_seen_call
                        ,cn.category
                        ,un.has_mention
                        ,ifnull(un.`status`, 0) `status`
                    FROM collection_notification cn
               LEFT JOIN user_notification un ON (un.collection_notification_id = cn.id AND un.user_id = pnUserId)
                    JOIN collection co ON cn.collection_id = co.id
                    JOIN user usr ON (co.user_id = usr.id)
                    JOIN collection_shared_member csm ON (csm.collection_id = co.id AND csm.shared_status = 1)
                   WHERE (pnCollectionId IS NULL OR co.id = pnCollectionId)
                     AND ifnull(co.is_trashed, 0) = 0
                     AND csm.member_user_id = pnUserId
                     AND cn.object_type <> 'CHAT'
                     AND co.type = 3 -- share only
                     -- only LOAD missed CALL notifications following the actions below:
                     -- call_in_declined    = 123
                     -- call_in_not_answer  = 124
                     -- call_in_cancel      = 125
                     AND (cn.action NOT IN (123, 124, 125) OR cn.user_id = pnUserId)
                     AND IF(isnull(pvObjectType), 1, find_in_set(cn.object_type, pvObjectType))
                     AND IF(cn.action IN (31, 61), un.has_mention = 1, 1)
                     AND un.deleted_date IS NULL -- sprint 17.2 soft DELETE notification
                     AND (pnCollectionId IS NULL OR cn.collection_id = pnCollectionId)
                     AND (pnChannelId IS NULL OR cn.channel_id = pnChannelId)
                     AND IF(cn.`action` IN (23, 24), cn.user_id = pnUserId, 1)
                     AND IF(isnull(pvAction), 1,
                          (-- find exactly action
                            find_in_set(cn.`action`, pvAction)
                            -- for comment
                            OR CASE 
                              WHEN find_in_set(6, pvAction)
                              THEN (cn.action = 61 AND un.has_mention = 1) OR find_in_set(cn.`action`, pvAction)
                              WHEN find_in_set(63, pvAction)
                              THEN un.has_mention = 1 AND cn.action IN (6, 61)
                            END 
                            -- for chat
                          OR CASE 
                              WHEN find_in_set(30, pvAction)
                              THEN (cn.action = 31 AND un.has_mention = 1) OR find_in_set(cn.`action`, pvAction)
                              WHEN find_in_set(33, pvAction)
                              THEN un.has_mention = 1 AND cn.action IN (30, 31)
                            END
                          )
                        )
                     -- 0: ALL (DEFAULT) 
                     AND (find_in_set(0, vStatus)
                        OR (-- 1: New
                            IF(find_in_set(1, vStatus), unix_timestamp(now(3) - INTERVAL 1 day) <= cn.created_date, 1)
                            -- 2: READ
                            AND IF(find_in_set(2, vStatus), un.`status` = 1, 1)
                            -- 3: Unread
                            AND IF(find_in_set(3, vStatus), un.`status` = 0, 1)
                            -- 4: Closed
                            AND IF(find_in_set(4, vStatus), ifnull(un.status, 0) = 2, 1)
                          )
                      )
                     -- 0: ALL (DEFAULT) 
                     AND (find_in_set(0, vAssignment)
                        OR (
                        cn.object_type = 'VTODO' AND (
                        -- 4: ALL VTODO
                            find_in_set(4, vAssignment)
                        -- 1: NOT Assigned
                        OR (find_in_set(1, vAssignment) AND (ifnull(cn.assignees, '') = '' OR cn.action = 18)) -- 18 >> Un-Assigned 
                        -- 2: Assigned TO Me 
                        OR (find_in_set(2, vAssignment) AND cn.action = 17 AND find_in_set(pvUsername, ifnull(cn.assignees, 'NA')))
                        -- 3: Assigned BY Me
                        OR (find_in_set(3, vAssignment) AND cn.email = pvUsername AND cn.action = 17)
                        )
                      )
                     )
                     -- <> 1 - NOT GET shared kanban
                     AND IF(ifnull(pnIncludeShared, 0) = 1, 1, cn.`action` NOT IN (20, 21, 22))
                     -- pnIncludeReaction = 1: chat, 2: comment, 3: BOTH
                     --  reaction chat
                   AND IF(ifnull(pnIncludeReaction, 0) IN (1,3), 1, cn.`action` <> 23)
                   -- reaction comment
                   AND IF(ifnull(pnIncludeReaction, 0) IN (2,3), 1, cn.`action` <> 24)
                   -- <> 1 - NOT GET personal notification: 23,24 for included reaction
                   AND IF(ifnull(pnIncludePersonal, 0) = 1, 1, cn.`action` NOT IN (19, 30, 31, 70, 80, 81))
           LIMIT 1100
            ) t2
           UNION -- member conference
          SELECT t3.id, t3.collection_id, t3.channel_id, t3.`action`, t3.user_id, t3.content
                ,t3.object_type, t3.object_uid, t3.assignees, t3.email, t3.actor
                ,t3.action_time, t3.comment_id, t3.created_date, t3.updated_date
                ,t3.kanban_id, t3.emoji_unicode
                ,t3.owner_calendar_uri, t3.owner_user_id
                ,t3.member_calendar_uri, t3.member_email, t3.member_user_id
                ,t3.owner_username, t3.account_id
                ,t3.last_seen_chat, t3.last_seen_call, t3.category
                ,t3.has_mention
                ,t3.status
            FROM (SELECT cn.id, cn.collection_id, cn.channel_id, cn.`action`, cn.user_id, cn.content
                        ,cn.object_type, cn.object_uid, cn.assignees, cn.email, cn.actor
                        ,COALESCE(un.action_time, cn.action_time, 0) action_time, cn.comment_id, cn.created_date, greatest(cn.updated_date, ifnull(un.updated_date, 0)) updated_date
                        ,cn.kanban_id, cn.emoji_unicode
                        ,'' COLLATE utf8mb4_0900_ai_ci owner_calendar_uri, '' COLLATE utf8mb4_0900_ai_ci owner_user_id, '' COLLATE utf8mb4_0900_ai_ci member_calendar_uri
                        ,'' COLLATE utf8mb4_0900_ai_ci member_email, 0 member_user_id, '' COLLATE utf8mb4_0900_ai_ci owner_username, cn.account_id
                        ,rculs.last_message_created_date last_seen_chat
                        ,cm.last_seen_call
                        ,cn.category
                        ,un.has_mention
                        ,CASE 
                            WHEN cn.object_type = 'CHAT'
                                  AND IFNULL(un.`status`, 0) = 0 
                                  AND IFNULL(rculs.last_message_created_date, 0) > 0
                                  AND rculs.last_message_created_date >= GREATEST(cn.created_date, ifnull(un.updated_date, cn.updated_date))
                            THEN 1
                              WHEN cn.object_type = 'CALL'
                                  AND IFNULL(un.`status`, 0) = 0 
                                  AND IFNULL(cm.last_seen_call, 0) > 0
                                  AND cm.last_seen_call >= GREATEST(cn.created_date, ifnull(un.updated_date, cn.updated_date))
                            THEN 1
                            ELSE ifnull(un.`status`, 0)
                          END `status`
                    FROM collection_notification cn 
               LEFT JOIN user_notification un ON (un.collection_notification_id = cn.id AND un.user_id = pnUserId)
                    JOIN conference_member cm ON (cn.channel_id = cm.channel_id)
                    JOIN conference_channel cc ON (cc.id = cm.channel_id)
                    JOIN `user` u ON (u.id = cm.user_id)
                    JOIN realtime_channel rc ON (rc.type = 'CONFERENCE' AND cc.id = rc.internal_channel_id)
                    JOIN realtime_channel_member rcm ON (rc.id = rcm.channel_id AND rcm.email = u.email)
                    JOIN realtime_chat_channel_user_last_seen rculs ON (rculs.channel_id = rc.id AND rculs.email = u.email)
                   WHERE (pnChannelId IS NULL OR cc.id = pnChannelId)
                     AND cm.user_id = pnUserId
                     -- only LOAD missed CALL notifications following the actions below:
                     -- call_in_declined    = 123
                     -- call_in_not_answer  = 124
                     -- call_in_cancel      = 125
                     AND (cn.action NOT IN (123, 124, 125) OR cn.user_id = pnUserId)
                     AND cc.is_trashed = 0
                     AND cm.revoke_time = 0
                     AND cn.created_date >= cm.join_time
                     AND IF(isnull(pvObjectType), 1, find_in_set(cn.object_type, pvObjectType))
                     AND IF(cn.action IN (31, 61), un.has_mention = 1, 1)
                     AND un.deleted_date IS NULL -- sprint 17.2 soft DELETE notification
                     AND (pnCollectionId IS NULL OR cn.collection_id = pnCollectionId)
                     AND (pnChannelId IS NULL OR cn.channel_id = pnChannelId)
                     AND IF(cn.`action` IN (23, 24), cn.user_id = pnUserId, 1)
                     AND IF(isnull(pvAction), 1,
                          (-- find exactly action
                            find_in_set(cn.`action`, pvAction)
                            -- for comment
                            OR CASE 
                              WHEN find_in_set(6, pvAction)
                              THEN (cn.action = 61 AND un.has_mention = 1) OR find_in_set(cn.`action`, pvAction)
                              WHEN find_in_set(63, pvAction)
                              THEN un.has_mention = 1 AND cn.action IN (6, 61)
                            END 
                            -- for chat
                          OR CASE 
                              WHEN find_in_set(30, pvAction)
                              THEN (cn.action = 31 AND un.has_mention = 1) OR find_in_set(cn.`action`, pvAction)
                              WHEN find_in_set(33, pvAction)
                              THEN un.has_mention = 1 AND cn.action IN (30, 31)
                            END
                          )
                        )
                     -- 0: ALL (DEFAULT) 
                     AND (find_in_set(0, vStatus)
                        OR (-- 1: New
                            IF(find_in_set(1, vStatus), unix_timestamp(now(3) - INTERVAL 1 day) <= cn.created_date, 1)
                            -- 2: READ
                            AND IF(find_in_set(2, vStatus), (CASE 
                                                              WHEN IFNULL(un.`status`, 0) = 0 
                                                                    AND IFNULL(rculs.last_message_created_date, 0) > 0
                                                                    AND rculs.last_message_created_date >= GREATEST(cn.created_date, ifnull(un.updated_date, cn.updated_date))
                                                              THEN 1
                                                              ELSE un.`status`
                                                            END) = 1, 1)
                            -- 3: Unread
                            AND IF(find_in_set(3, vStatus), (CASE 
                                                              WHEN IFNULL(un.`status`, 0) = 0 
                                                                    AND IFNULL(rculs.last_message_created_date, 0) > 0
                                                                    AND rculs.last_message_created_date >= GREATEST(cn.created_date, ifnull(un.updated_date, cn.updated_date))
                                                              THEN 1
                                                              ELSE un.`status`
                                                            END) = 0, 1)
                            -- 4: Closed
                            AND IF(find_in_set(4, vStatus), ifnull(un.status, 0) = 2, 1)
                          )
                      )
                     -- 0: ALL (DEFAULT) 
                     AND (find_in_set(0, vAssignment)
                        OR (
                        cn.object_type = 'VTODO' AND (
                        -- 4: ALL VTODO
                            find_in_set(4, vAssignment)
                        -- 1: NOT Assigned
                        OR (find_in_set(1, vAssignment) AND (ifnull(cn.assignees, '') = '' OR cn.action = 18)) -- 18 >> Un-Assigned 
                        -- 2: Assigned TO Me 
                        OR (find_in_set(2, vAssignment) AND cn.action = 17 AND find_in_set(pvUsername, ifnull(cn.assignees, 'NA')))
                        -- 3: Assigned BY Me
                        OR (find_in_set(3, vAssignment) AND cn.email = pvUsername AND cn.action = 17)
                        )
                      )
                     )
                     -- <> 1 - NOT GET shared kanban
                     AND IF(ifnull(pnIncludeShared, 0) = 1, 1, cn.`action` NOT IN (20, 21, 22))
                     -- pnIncludeReaction = 1: chat, 2: comment, 3: BOTH
                     --  reaction chat
                     AND IF(ifnull(pnIncludeReaction, 0) IN (1,3), 1, cn.`action` <> 23)
                     -- reaction comment
                     AND IF(ifnull(pnIncludeReaction, 0) IN (2,3), 1, cn.`action` <> 24)
                     -- <> 1 - NOT GET personal notification: 23,24 for included reaction
                     AND IF(ifnull(pnIncludePersonal, 0) = 1, 1, cn.`action` NOT IN (19, 30, 31, 70, 80, 81))
                   LIMIT 1100
             ) t3
           UNION
           -- invidual notification
          SELECT t4.id, t4.collection_id, t4.channel_id, t4.`action`, t4.user_id, t4.content
                ,t4.object_type, t4.object_uid, t4.assignees, t4.email, t4.actor
                ,t4.action_time, t4.comment_id, t4.created_date, t4.updated_date
                ,t4.kanban_id, t4.emoji_unicode
                ,t4.owner_calendar_uri, t4.owner_user_id
                ,t4.member_calendar_uri, t4.member_email, t4.member_user_id
                ,t4.owner_username, t4.account_id
                ,t4.last_seen_chat, t4.last_seen_call, t4.category
                ,t4.has_mention
                ,t4.status
            FROM (SELECT cn.id, cn.collection_id, cn.channel_id, cn.`action`, cn.user_id, cn.content
                         ,cn.object_type, cn.object_uid, cn.assignees, cn.email, cn.actor
                         ,COALESCE(un.action_time, cn.action_time, 0) action_time, cn.comment_id, cn.created_date, greatest(cn.updated_date, ifnull(un.updated_date, 0)) updated_date
                         ,cn.kanban_id, cn.emoji_unicode
                         ,'' COLLATE utf8mb4_0900_ai_ci owner_calendar_uri, '' COLLATE utf8mb4_0900_ai_ci owner_user_id, '' COLLATE utf8mb4_0900_ai_ci member_calendar_uri
                         ,'' COLLATE utf8mb4_0900_ai_ci member_email, 0 member_user_id, '' COLLATE utf8mb4_0900_ai_ci owner_username, cn.account_id
                         ,0 last_seen_chat
                         ,0 last_seen_call
                         ,cn.category
                         ,un.has_mention
                         ,ifnull(un.`status`, 0) `status`
                     FROM collection_notification cn
                LEFT JOIN user_notification un ON (un.collection_notification_id = cn.id AND un.user_id = pnUserId)
                    WHERE cn.user_id = pnUserId
                      AND cn.collection_id = 0
                      AND cn.channel_id = 0
                      AND ifnull(pnCollectionId, 0) = 0
                      AND ifnull(pnChannelId, 0) = 0
                      AND IF(isnull(pvObjectType), 1, find_in_set(cn.object_type, pvObjectType))
                      
                      AND IF(cn.action IN (31, 61), un.has_mention = 1, 1)
                      AND un.deleted_date IS NULL -- sprint 17.2 soft DELETE notification
                      AND (pnCollectionId IS NULL OR cn.collection_id = pnCollectionId)
                      AND (pnChannelId IS NULL OR cn.channel_id = pnChannelId)
                      AND IF(cn.`action` IN (23, 24), cn.user_id = pnUserId, 1)
                      AND IF(isnull(pvAction), 1,
                            (-- find exactly action
                              find_in_set(cn.`action`, pvAction)
                              -- for comment
                              OR CASE 
                                WHEN find_in_set(6, pvAction)
                                THEN (cn.action = 61 AND un.has_mention = 1) OR find_in_set(cn.`action`, pvAction)
                                WHEN find_in_set(63, pvAction)
                                THEN un.has_mention = 1 AND cn.action IN (6, 61)
                              END 
                              -- for chat
                            OR CASE 
                                WHEN find_in_set(30, pvAction)
                                THEN (cn.action = 31 AND un.has_mention = 1) OR find_in_set(cn.`action`, pvAction)
                                WHEN find_in_set(33, pvAction)
                                THEN un.has_mention = 1 AND cn.action IN (30, 31)
                              END
                            )
                          )
                      -- 0: ALL (DEFAULT) 
                      AND (find_in_set(0, vStatus)
                          OR (-- 1: New
                              IF(find_in_set(1, vStatus), unix_timestamp(now(3) - INTERVAL 1 day) <= cn.created_date, 1)
                              -- 2: READ
                              AND IF(find_in_set(2, vStatus), un.`status` = 1, 1)
                              -- 3: Unread
                              AND IF(find_in_set(3, vStatus), un.`status` = 0, 1)
                              -- 4: Closed
                              AND IF(find_in_set(4, vStatus), ifnull(un.status, 0) = 2, 1)
                            )
                        )
                      -- 0: ALL (DEFAULT) 
                      AND (find_in_set(0, vAssignment)
                          OR (
                          cn.object_type = 'VTODO' AND (
                          -- 4: ALL VTODO
                              find_in_set(4, vAssignment)
                          -- 1: NOT Assigned
                          OR (find_in_set(1, vAssignment) AND (ifnull(cn.assignees, '') = '' OR cn.action = 18)) -- 18 >> Un-Assigned 
                          -- 2: Assigned TO Me 
                          OR (find_in_set(2, vAssignment) AND cn.action = 17 AND find_in_set(pvUsername, ifnull(cn.assignees, 'NA')))
                          -- 3: Assigned BY Me
                          OR (find_in_set(3, vAssignment) AND cn.email = pvUsername AND cn.action = 17)
                          )
                        )
                      )
                      -- <> 1 - NOT GET shared kanban
                      AND IF(ifnull(pnIncludeShared, 0) = 1, 1, cn.`action` NOT IN (20, 21, 22))
                      -- pnIncludeReaction = 1: chat, 2: comment, 3: BOTH
                      --  reaction chat
                    AND IF(ifnull(pnIncludeReaction, 0) IN (1,3), 1, cn.`action` <> 23)
                    -- reaction comment
                    AND IF(ifnull(pnIncludeReaction, 0) IN (2,3), 1, cn.`action` <> 24)
                    -- <> 1 - NOT GET personal notification: 23,24 for included reaction
                    AND IF(ifnull(pnIncludePersonal, 0) = 1, 1, cn.`action` NOT IN (19, 30, 31, 70, 80, 81))
            LIMIT 1100
              ) t4
     ) cn
      ;
  RETURN nReturn;
END