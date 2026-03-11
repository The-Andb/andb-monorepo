CREATE PROCEDURE `n2025_listOfNotification`(
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
  ,pnIncludeShared    TINYINT(1)
  ,pnIncludeReaction  TINYINT(1)     -- 1: chat, 2: comment, 3: BOTH
)
BEGIN
   -- only SHOW notification edited FOR mentioned member
  DECLARE vStatus           VARCHAR(20) DEFAULT ifnull(pvStatus, '0');
  DECLARE vAssignment       VARCHAR(20) DEFAULT ifnull(pvAssignment, '0');
  DECLARE nOFFSET           INT(11) DEFAULT 0;
  DECLARE vFieldSort        VARCHAR(50) DEFAULT REPLACE(REPLACE(IFNULL(pvSort, ''), '-', ''), '+', '');                                              
  DECLARE vSort             VARCHAR(50) DEFAULT IF(IFNULL(pvSort, '') <> '' -- DEFAULT +: ASC
                                                  AND NOT instr(pvSort, '-') 
                                                  AND NOT instr(pvSort, '+')
                                                 ,concat('+', pvSort), pvSort);
  --
  IF ifnull(pvSort, 'NA') <> 'NA' THEN
    --
    SET nOFFSET = IF(ifnull(pnPageNo, 0) = 0, 0, (pnPageNo - 1) * pnPageSize);
    --
  END IF;
  --
  SELECT cn.id, ifnull(cn.actor, cn.email) email, cn.collection_id, ifnull(cn.channel_id, 0) channel_id
        ,cn.object_uid, cn.object_type
        ,CASE
            WHEN cn.`action` IN (6, 61) AND un.has_mention = 1
            THEN 63 -- VIRTUAL action: 63 - MENTIONED COMMENT
            WHEN cn.`action` IN (30, 31) AND un.has_mention = 1
            THEN 33 -- VIRTUAL action: 33 - MENTIONED CHAT
            ELSE cn.action
         END `action`
        ,cn.content, cn.action_time, cn.comment_id
        ,cn.created_date
        ,greatest(cn.updated_date, ifnull(un.updated_date, 0)) updated_date
        ,cn.member_calendar_uri, cn.member_email, cn.member_user_id
        ,cn.owner_user_id, cn.owner_calendar_uri, cn.owner_username, cn.owner_user_id
        ,IF(cn.object_type NOT IN ('VEVENT', 'VJOURNAL', 'VTODO') 
             ,''
             ,concat("/calendarserver.php/calendars/"
               ,cn.owner_username, "/"
               ,cn.owner_calendar_uri, "/"
               ,CONVERT(cn.object_uid USING cp1251), ".ics"
               )
             ) object_href
        ,(CASE
            WHEN cn.object_type = 'VEVENT' THEN ifnull(ce.summary, '')
            WHEN cn.object_type = 'VJOURNAL' THEN ifnull(cn1.summary, '')
            WHEN cn.object_type = 'VTODO' THEN ifnull(ct.summary, '')
            WHEN cn.object_type = 'URL' THEN ifnull(url.title, '')
            ELSE ''
          END) last_object_title
        ,ifnull(un.`status`, 0) `status`, cn.kanban_id, cn.assignees
        ,ifnull(cn.emoji_unicode, '') `emoji_unicode`
        ,cn.account_id
     FROM (
          -- owner existed collection_id
          SELECT cn.id, cn.collection_id, cn.channel_id, cn.`action`, cn.user_id, cn.content
                ,cn.object_type, cn.object_uid, cn.assignees, cn.email, cn.actor
                ,cn.action_time, cn.comment_id, cn.created_date, cn.updated_date
                ,cn.kanban_id, cn.emoji_unicode
              ,co.calendar_uri owner_calendar_uri, co.user_id owner_user_id
                ,'' member_calendar_uri, '' member_email, 0 member_user_id
                ,usr.username owner_username, cn.account_id
            FROM collection_notification cn
            JOIN collection co ON cn.collection_id = co.id
            JOIN user usr ON (co.user_id = usr.id)
           WHERE co.id = IF(ifnull(pnCollectionId, 0) > 0, pnCollectionId, co.id)
             AND co.`type` = IF(ifnull(pnCollectionId, 0) > 0, co.`type`, 3) -- owner GET BY uid? dont need TO share
             AND co.user_id = pnUserId
             AND cn.channel_id = 0
          -- member existed collection_id
          UNION
          SELECT cn.id, cn.collection_id, cn.channel_id, cn.`action`, cn.user_id, cn.content
                ,cn.object_type, cn.object_uid, cn.assignees, cn.email, cn.actor
                ,cn.action_time, cn.comment_id, cn.created_date, cn.updated_date
                ,cn.kanban_id, cn.emoji_unicode
                ,co.calendar_uri owner_calendar_uri, co.user_id owner_user_id
                ,csm.calendar_uri member_calendar_uri, csm.shared_email member_email, csm.member_user_id
                ,usr.username owner_username, cn.account_id
            FROM collection_notification cn 
            JOIN collection co ON cn.collection_id = co.id
            JOIN user usr ON (co.user_id = usr.id)
            JOIN collection_shared_member csm ON (csm.collection_id = co.id AND csm.shared_status = 1)
           WHERE co.id = IF(ifnull(pnCollectionId, 0) > 0, pnCollectionId, co.id)
             AND ifnull(co.is_trashed, 0) = 0
             AND csm.member_user_id = pnUserId
--              AND cn.channel_id = 0 -- fix CASE user chat INTO channel_id of collection
             AND co.type = 3 -- share only
              -- member conference
           UNION
          SELECT cn.id, cn.collection_id, cn.channel_id, cn.`action`, cn.user_id, cn.content
                ,cn.object_type, cn.object_uid, cn.assignees, cn.email, cn.actor
                ,cn.action_time, cn.comment_id, cn.created_date, cn.updated_date
                ,cn.kanban_id, cn.emoji_unicode
                ,'' owner_calendar_uri, '' owner_user_id, '' member_calendar_uri
                ,'' member_email, 0 member_user_id, '' owner_username, cn.account_id
            FROM collection_notification cn 
            JOIN conference_member cm ON cn.channel_id = cm.channel_id
            JOIN conference_channel cc ON (cc.id = cm.channel_id)
           WHERE cc.id = IF(ifnull(pnChannelId, 0) > 0, pnChannelId, cc.id)
             AND cm.user_id = pnUserId
             AND cc.is_trashed = 0
             AND cm.revoke_time = 0
           UNION
           -- invidual notification
           SELECT cn.id, cn.collection_id, cn.channel_id, cn.`action`, cn.user_id, cn.content
                 ,cn.object_type, cn.object_uid, cn.assignees, cn.email, cn.actor
                 ,cn.action_time, cn.comment_id, cn.created_date, cn.updated_date
                 ,cn.kanban_id, cn.emoji_unicode
                 ,'' owner_calendar_uri, '' owner_user_id, '' member_calendar_uri
                 ,'' member_email, 0 member_user_id, '' owner_username, cn.account_id
             FROM collection_notification cn
            WHERE cn.user_id = pnUserId
              AND cn.collection_id = 0
              AND cn.channel_id = 0
              AND ifnull(pnCollectionId, 0) = 0
              AND ifnull(pnChannelId, 0) = 0
       ) cn
LEFT JOIN user_notification un ON (un.collection_notification_id = cn.id AND un.user_id = pnUserId)
LEFT JOIN cal_event ce ON (cn.object_uid = ce.uid AND cn.object_type = 'VEVENT')  
LEFT JOIN cal_note cn1 ON (cn.object_uid = cn1.uid AND cn.object_type = 'VJOURNAL')  
LEFT JOIN cal_todo ct ON (cn.object_uid = ct.uid AND cn.object_type = 'VTODO')  
LEFT JOIN url ON (cn.object_uid = url.uid AND cn.object_type = 'URL')
    -- GET BY collection id
    WHERE cn.collection_id = IF(ifnull(pnCollectionId, 0) > 0, pnCollectionId, cn.collection_id)
      AND cn.channel_id = IF(ifnull(pnChannelId, 0) > 0, pnChannelId, cn.channel_id)
      -- <> 1 - NOT GET shared kanban
      AND IF(ifnull(pnIncludeShared, 0) = 1, 1, cn.`action` NOT IN (20, 21, 22))
      -- reaction, owner GET only
      AND IF(cn.`action` IN (23, 24), cn.user_id = pnUserId, 1)
      AND (
          cn.updated_date < IF(ifnull(pnModifiedLT, 0) > 0, pnModifiedLT, unix_timestamp() + 1)
          OR
          un.updated_date < IF(ifnull(pnModifiedLT, 0) > 0, pnModifiedLT, unix_timestamp() + 1)
          )
      AND (
          cn.updated_date >= IF(ifnull(pnModifiedGTE, 0) > 0, pnModifiedGTE, 0)
          OR
          un.updated_date >= IF(ifnull(pnModifiedGTE, 0) > 0, pnModifiedGTE, 0)
          )
      AND cn.id > IF(ifnull(pnMinId, 0) > 0, pnMinId, 0)
      AND un.deleted_date IS NULL -- sprint 17.2 soft DELETE notification
      AND IF(ifnull(pvIds,'NA') <> 'NA', FIND_IN_SET(cn.id, pvIds), 1)
        AND IF(isnull(pvAction), 1,
          CASE 
               -- for comment
               WHEN find_in_set(6, pvAction)
               THEN (cn.action = 61 AND un.has_mention = 1) OR find_in_set(cn.`action`, pvAction)
               WHEN find_in_set(63, pvAction)
               THEN un.has_mention = 1
               -- for chat
               WHEN find_in_set(30, pvAction)
               THEN (cn.action = 31 AND un.has_mention = 1) OR find_in_set(cn.`action`, pvAction)
               WHEN find_in_set(33, pvAction)
               THEN un.has_mention = 1
               -- rest CASE find exactly action
               ELSE find_in_set(cn.`action`, pvAction)
            END
        )
        -- only GET noti UPDATE comment FOR CASE mention
        AND IF(cn.action IN (31, 61), un.has_mention = 1, 1)
        AND IF(isnull(pvObjectType), 1, find_in_set(cn.object_type, pvObjectType))
      -- 0: ALL (DEFAULT) 
      AND (find_in_set(0, vStatus)
          OR (-- 1: New
              IF(find_in_set(1, vStatus), unix_timestamp(now(3) - INTERVAL 1 day) <= cn.created_date, 1)
              -- 2: READ
              AND IF(find_in_set(2, vStatus), ifnull(un.status, 0) = 1, 1)
              -- 3: Unread
              AND IF(find_in_set(3, vStatus), ifnull(un.status, 0) = 0, 1)
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
       -- pnIncludeReaction = 1: chat, 2: comment, 3: BOTH
       --  reaction chat
       AND IF((ifnull(pnIncludeReaction, 0)) IN (1,3) 
            OR ifnull(pvObjectType, '') = 'CHAT'
            OR ifnull(pvAction, 0) = 23, 1, cn.`action` <> 23
      )-- reaction comment
       AND IF(ifnull(pnIncludeReaction, 0) IN (2,3) 
           OR ifnull(pvObjectType, '') = 'COMMENT' 
           OR ifnull(pvAction, 0) = 24, 1, cn.`action` <> 24
      )
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
               --
              END
           --
         END) ASC
        
   LIMIT pnPageSize
  OFFSET nOFFSET;
  --
END