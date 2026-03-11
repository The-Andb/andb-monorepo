CREATE PROCEDURE `c2025_listOfConference`(pvKeyword         TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
                                                            ,pvEmails          TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
                                                            ,pnFilterType      TINYINT(1)
                                                            ,pnFindBy          TINYINT(1)-- find link only
                                                            ,pvCollectionIds   TEXT -- find link only
                                                            ,pvChannelIDs      TEXT
                                                            ,pvChannelUIDs     TEXT
                                                            ,pnUserId          BIGINT(20)
                                                            ,pvIDs             TEXT
                                                            ,pnModifiedGTE     DOUBLE(14,4)
                                                            ,pnModifiedLT      DOUBLE(14,4)
                                                            ,pnMinId           BIGINT(20)
                                                            ,pnVip             TINYINT(1)
                                                            ,pnPageSize        INTEGER(11)
                                                            ,pnPageNo          INTEGER(11)
                                                            ,pvSort            VARCHAR(128)
                                                            ,pnIncludeShared   TINYINT(1))
BEGIN
  --
  DECLARE nOFFSET       INT(11) DEFAULT 0;
  DECLARE vSort         VARCHAR(50) DEFAULT IF(pvSort IS NOT NULL AND pvSort NOT LIKE '%-%' AND pvSort NOT LIKE '%+%'
                                              ,CONCAT('+', pvSort)
                                              ,IFNULL(pvSort, IF(pnPageNo IS NULL, NULL, '-start_time'))
                                             ); -- DEFAULT BY page_no
  DECLARE vFieldSort    VARCHAR(50) DEFAULT REPLACE(REPLACE(IFNULL(vSort, ''), '-', ''), '+', '');
  DECLARE vKeyword      TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '';
  DECLARE vKeyword1     TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '';
  DECLARE vKeyword2     TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '';
  DECLARE nFilterType   TEXT DEFAULT ifnull(pnFilterType, 1);
  DECLARE nModifiedLT   DOUBLE(14,4) DEFAULT IF(ifnull(pnModifiedLT, 0) > 0, pnModifiedLT, unix_timestamp() + 1);
  DECLARE nModifiedGTE  DOUBLE(14,4) DEFAULT IF(ifnull(pnModifiedGTE, 0) > 0, pnModifiedGTE, 0);
  -- UPDATE for MySQL 8.0+
  SET @raw_kw = IFNULL(pvKeyword, '');
  --
  SET vKeyword = REGEXP_REPLACE(
                 @raw_kw,
                 '([\\^.$|?*+()\\[\\]{}\\\\])',
                 '\\\\$1');
  -- Determine IF the keyword contains “letters/numbers” OR just punctuation
  IF @raw_kw = '' OR @raw_kw REGEXP '[[:alnum:]]' THEN
    -- Contains letters/numbers: USE boundaries TO avoid blind matches
    -- value = 1 >> search BY channel name (keyword=channel name) 
    SET vKeyword1 = CONCAT('( ',vKeyword,')|(^',vKeyword,')');
    -- value = 2 >> search BY participant 
    SET vKeyword2 = CONCAT('( ',vKeyword,')|(^',vKeyword,')|(@',vKeyword,')');
    --
  ELSE
    -- full special CHARACTER: MATCH anywhere
    SET vKeyword1 = vKeyword;
    SET vKeyword2 = vKeyword;
    --
  END IF;
  -- 
  --
  SET nOFFSET = IF(ifnull(pnPageNo, 0) > 0, (pnPageNo - 1) * pnPageSize, 0);
  --
  SELECT cm.id, ifnull(cc.collection_id, 0) collection_id, cm.channel_id, cc.uid, cm.email, cm.is_creator, cm.description
        ,cm.vip, cm.revoke_time, greatest(cm.updated_date, cc.updated_date) updated_date, cm.created_date, cm.join_time
        ,ifnull(cm.view_chat_history, 1) view_chat_history
        ,cc.room_url, ifnull(cc.enable_chat_history, 1) enable_chat_history
        ,IF(ifnull(cc.collection_id,0) > 0
            ,cc.title -- always USE share title for shared channel
            ,COALESCE(NULLIF(cm.title, ''), cc.title, '')) title
        ,cc.title share_title
        ,ch.start_time, ch.end_time, ch.action_time, ch.status, ch.type
        ,cc.last_used
        ,cc.realtime_channel
        ,cm.notification_chat, cm.notification_call
        ,cm.missed_calls, cm.last_missed_call
     FROM conference_channel cc
     JOIN conference_member cm ON (cm.channel_id = cc.id)
     JOIN `user` u ON (u.id = cm.user_id)
     JOIN realtime_channel rc ON (rc.type = 'CONFERENCE' AND cc.id = rc.internal_channel_id)
     JOIN realtime_channel_member rcm ON (rc.id = rcm.channel_id AND rcm.email = u.email)
LEFT JOIN realtime_chat_channel_user_last_seen rculs ON (rculs.channel_id = rc.id AND rculs.email = u.email)
LEFT JOIN conference_history ch ON (cm.id = ch.member_id AND cm.user_id = ch.user_id AND ch.id = cm.last_history_id)
LEFT JOIN conference_member cm1 ON (cc.id = cm1.channel_id)
LEFT JOIN linked_collection_object lco ON (cc.uid = lco.object_uid 
                                           AND cm.user_id = lco.user_id 
                                           AND lco.object_type = 'CONFERENCING' 
                                           AND ifnull(lco.is_trashed, 0) = 0
                                          )
-- LEFT JOIN collection co ON (co.id = cc.collection_id)
    WHERE cm.user_id = pnUserId
      AND (cc.collection_id IS NULL
          OR (cc.collection_id IS NOT NULL AND EXISTS (
                SELECT 1
                  FROM collection co
                  WHERE cc.collection_id = co.id
                    AND co.is_trashed = 0
               )
             )
          )
      AND (cm.revoke_time = 0 -- NOT revoked
           OR (cm1.revoke_time > 0  -- revoked
               AND cm1.user_id = pnUserId -- ..but me
               AND ifnull(cc.collection_id, 0) = 0) -- ..NOT belongs TO shared channel
           )
      -- Collection NOT trashed
      -- AND (cc.collection_id IS NULL OR co.is_trashed = 0)
      AND cc.is_trashed = 0
      AND (cm1.revoke_time = 0 -- NOT revoked
            OR (cm1.revoke_time > 0  -- revoked
               AND cm1.user_id = pnUserId -- ..but me
               AND ifnull(cc.collection_id, 0) = 0) -- ..NOT belongs TO shared channel
          )
      AND (cm.updated_date < nModifiedLT    AND cc.updated_date < nModifiedLT)
      AND (cm.updated_date >= nModifiedGTE  OR cc.updated_date >= nModifiedGTE OR ifnull(ch.updated_date, 0) >= nModifiedGTE)
      AND (pnMinId IS NULL         OR cm.id > pnMinId)
      AND (pnVip IS NULL           OR cm.vip = pnVip)
      AND (pvIDs IS NULL           OR FIND_IN_SET(cm.id, pvIDs))
      AND (pvChannelUIDs IS NULL   OR FIND_IN_SET(cc.uid, pvChannelUIDs))
      AND (pvChannelIDs IS NULL    OR FIND_IN_SET(cc.id, pvChannelIDs))
      AND (pvCollectionIds IS NULL 
           OR IF(pnFindBy = 1
                ,FIND_IN_SET(cc.collection_id, pvCollectionIds) -- GET channel
                ,FIND_IN_SET(lco.collection_id, pvCollectionIds) -- GET link only
                )
          )
      -- AND IF(pvCollectionIds IS NOT NULL, , 1)
      -- <> 1 - NOT GET channel belong TO collection
      AND IF(ifnull(pnIncludeShared, 0) = 1, 1, cc.collection_id IS NULL)
      -- value = 1 >> search BY channel name (keyword=channel name) 
      AND IF(nFilterType = 1, COALESCE(cm.title, cc.title, '') RLIKE vKeyword1, 1)
      -- value = 2 >> search BY participant 
      AND IF(nFilterType <> 2, 1, EXISTS (
            SELECT 1
              FROM conference_member cm2
             WHERE cm2.channel_id = cc.id
               AND cm2.user_id <> pnUserId
               AND cm2.revoke_time = 0
               AND CASE
                     -- 1. email & keyword                 
                     WHEN NOT isnull(pvKeyword) AND NOT isnull(pvEmails)
                       THEN (cm2.email RLIKE vKeyword2 OR FIND_IN_SET(cm2.email, pvEmails))
                     -- 2. email & keyword = blank
                     WHEN isnull(pvKeyword) AND NOT isnull(pvEmails)
                       THEN FIND_IN_SET(cm2.email, pvEmails)
                     -- 3. email=blank & keyword
                     WHEN NOT isnull(pvKeyword) AND isnull(pvEmails)
                       THEN cm2.email RLIKE vKeyword2
                     ELSE 1
                     --
                    END
         ))
      -- value = 3,4,5,6,7,8 >> search BY channel name || participant 
      AND (IF(nFilterType IN (3,4,5,6,7,8)
           -- search BY title
          ,IF(isnull(pvKeyword) AND NOT isnull(pvEmails)
             ,0
             ,COALESCE(cm.title, cc.title, '') RLIKE vKeyword1)
          -- search BY participant's emails
          OR EXISTS (
             SELECT 1
               FROM conference_member cm2
              WHERE cm2.channel_id = cc.id
                AND cm2.user_id <> pnUserId
                AND cm2.revoke_time = 0
                AND CASE
                      -- 1. email & keyword                 
                      WHEN NOT isnull(pvKeyword) AND NOT isnull(pvEmails)
                        THEN (cm2.email RLIKE vKeyword2 OR FIND_IN_SET(cm2.email, pvEmails))
                      -- 2. email & keyword = blank
                      WHEN isnull(pvKeyword) AND NOT isnull(pvEmails)
                        THEN FIND_IN_SET(cm2.email, pvEmails)
                      -- 3. email=blank & keyword
                      WHEN NOT isnull(pvKeyword) AND isnull(pvEmails)
                        THEN cm2.email RLIKE vKeyword2
                     ELSE 1
                      --
                     END
         ), 1)
        )
      -- value = 8: filter BY unread chat OR missed CALL
      AND (nFilterType NOT IN (4, 7, 8) 
           OR CASE
                -- value = 4: filter BY missed CALL
                WHEN nFilterType = 4 
                  THEN cm.missed_calls > 0
                -- value = 7: filter BY unread chat
                WHEN nFilterType = 7 
                  THEN rculs.unread > 0
                -- value = 8 (4+7): filter BY unread chat OR missed CALL
                WHEN nFilterType = 8 
                  THEN (cm.missed_calls > 0 OR rculs.unread > 0)
                --
              END
          )
      GROUP BY cc.id, cm.id, cm1.channel_id
      -- value = 5 >> 3 + only 1 participant
      HAVING nFilterType IN (1,2,3,4,7,8)
           OR (nFilterType = 5 
              AND count(DISTINCT cm1.id) = 2) -- only 2 member contained me
           -- value = 6: No Collection
           OR (nFilterType = 6 
              AND count(lco.id) = 0) -- no collection
      ORDER BY 
          (CASE
             WHEN vSort IS NOT NULL AND INSTR(vSort, "-") 
               THEN -- DEFAULT WHEN no ASC active
               CASE vFieldSort
                 WHEN 'start_time' 
                   THEN (GREATEST(ifnull(ch.updated_date, 0), cm.created_date, ifnull(cc.last_used, 0)) +
                          IF( -- missed CALL last 24h
                              nFilterType IN (1, 4, 8) AND 
                              UNIX_TIMESTAMP(NOW(3) - INTERVAL 1 DAY) < cm.last_missed_call
                              ,cm.last_missed_call
                              ,0
                            ))
                 --
                 WHEN 'action_time'  THEN ch.action_time
                 WHEN 'created_date' THEN cm.created_date
                 WHEN 'title'        THEN ifnull(cm.title, cc.title)
                 WHEN 'last_call'    THEN GREATEST(ifnull(ch.updated_date, 0), cc.created_date)
                 WHEN 'last_chat'    THEN GREATEST(ifnull(cc.last_used, 0), cc.created_date) -- last new chat
                 --
               END
             WHEN pnModifiedLT IS NOT NULL
               THEN GREATEST(cc.updated_date, cm.updated_date)
             --
         END) DESC,
        (CASE
           WHEN vSort IS NOT NULL AND  INSTR(vSort, "+") THEN
             CASE vFieldSort 
               WHEN 'start_time'
                 THEN (GREATEST(ifnull(ch.updated_date, 0), cm.created_date, ifnull(cc.last_used, 0)) +
                          IF( -- missed CALL last 24h
                              UNIX_TIMESTAMP(NOW(3) - INTERVAL 1 DAY) < cm.last_missed_call
                              ,cm.last_missed_call
                              ,0
                            ))
                 --
               WHEN 'action_time'  THEN ch.action_time
               WHEN 'created_date' THEN cm.created_date
               WHEN 'title'        THEN ifnull(cm.title, cc.title)
               WHEN 'last_call'    THEN GREATEST(ifnull(ch.updated_date, 0), cc.created_date)
               WHEN 'last_chat'    THEN GREATEST(ifnull(cc.last_used, 0), cc.created_date) -- last new chat
               --
              END
           WHEN NOT isnull(pnMinId) AND isnull(pnPageNo)
             THEN cm.id
           WHEN NOT isnull(pnModifiedGTE) AND isnull(pnPageNo)
             THEN GREATEST(cc.updated_date, cm.updated_date)
           --
         END) ASC
       --
       LIMIT pnPageSize
      OFFSET nOFFSET;
     --
    END