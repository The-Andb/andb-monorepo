CREATE PROCEDURE `n2025_listOfCollectionNotificationMember`(
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
  DECLARE vStatus           VARCHAR(20) DEFAULT ifnull(pvStatus, '0');
  DECLARE vAssignment       VARCHAR(20) DEFAULT ifnull(pvAssignment, '0'); 
  DECLARE nOFFSET           INT(11) DEFAULT 0;  
  DECLARE nLimit            INT(11) DEFAULT 5000;
  
 -- LEAVE n2025_listOfNotificationV4;
  SET @modifiedLT := IF(ifnull(pnModifiedLT, 0) > 0, pnModifiedLT, unix_timestamp() + 1);
  SET @modifiedGTE := IF(ifnull(pnModifiedGTE, 0) > 0, pnModifiedGTE, 0);
  --
  SELECT cn.id, cn.collection_id, cn.channel_id, cn.`action`, cn.user_id, cn.content
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
     AND cn.id > IF(ifnull(pnMinId, 0) > 0, pnMinId, 0)
     AND IF(isnull(pvObjectType), 1, find_in_set(cn.object_type, pvObjectType))
     AND IF(ifnull(pvIds,'NA') <> 'NA', FIND_IN_SET(cn.id, pvIds), 1)
     AND IF(cn.action IN (31, 61), un.has_mention = 1, 1)
     AND un.deleted_date IS NULL -- sprint 17.2 soft DELETE notification
     AND (pnCollectionId IS NULL OR cn.collection_id = pnCollectionId)
     AND (pnChannelId IS NULL OR cn.channel_id = pnChannelId)
     AND IF(cn.`action` IN (23, 24), cn.user_id = pnUserId, 1)
     AND ((un.id IS NULL OR un.updated_date < @modifiedLT)
        OR cn.updated_date < @modifiedLT)
     AND ((un.id IS NULL OR un.updated_date >= @modifiedGTE)
        OR cn.updated_date >= @modifiedGTE
     )
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
 LIMIT nLimit;
  --
END