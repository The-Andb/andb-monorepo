CREATE PROCEDURE `testc2025_listOfConferenceV2`(
 pvKeyword         TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
,pvEmails          TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci -- REQUIRE JSON format: ["abc@xzy.com",..]
,pnFilterType      TINYINT(2)
,pnFindBy          TINYINT(1)-- find link only
,pvCollectionIds   TEXT -- find link only
,pvChannelIDs      TEXT
,pvChannelUIDs     TEXT
,pvIDs             TEXT
,pnModifiedGTE     DOUBLE(14,4)
,pnModifiedLT      DOUBLE(14,4)
,pnMinId           BIGINT(20)
,pnVip             TINYINT(1)
,pnPageSize        INTEGER(11)
,pnPageNo          INTEGER(11)
,pvSort            VARCHAR(128)
,pnIncludeShared   TINYINT(1)
,pnUserId          BIGINT(20)
,pvEmail           VARCHAR(100))
BEGIN
  --
  DECLARE nOFFSET         INT UNSIGNED DEFAULT 0;
  DECLARE vSort           VARCHAR(50) DEFAULT IF(pvSort IS NOT NULL AND pvSort NOT LIKE '%-%' AND pvSort NOT LIKE '%+%'
                                              ,CONCAT('+', pvSort)
                                              ,IFNULL(pvSort, IF(pnPageNo IS NULL, NULL, '-start_time'))
                                             ); -- DEFAULT BY page_no
  DECLARE vFieldSort      VARCHAR(50) DEFAULT REPLACE(REPLACE(IFNULL(vSort, ''), '-', ''), '+', '');
  DECLARE vKeyword        TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '';
  DECLARE vKeyword1       TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '';
  DECLARE vKeyword2       TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '';
  DECLARE nFilterType     TINYINT(2) DEFAULT ifnull(pnFilterType, 1);
  DECLARE nModifiedLT     DOUBLE(14,4) DEFAULT IF(ifnull(pnModifiedLT, 0) > 0, pnModifiedLT, unix_timestamp() + 1);
  DECLARE nModifiedGTE    DOUBLE(14,4) DEFAULT IF(ifnull(pnModifiedGTE, 0) > 0, pnModifiedGTE, 0);
  DECLARE bHasKeyword     TINYINT(1) DEFAULT 0;
  DECLARE bHasEmails      TINYINT(1) DEFAULT 0;

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
  SET bHasKeyword = IF(pvKeyword IS NOT NULL AND TRIM(pvKeyword) <> '', 1, 0);
  SET bHasEmails  = IF(pvEmails  IS NOT NULL AND TRIM(pvEmails)  <> '', 1, 0);
  --
  SET nOFFSET = IF(ifnull(pnPageNo, 0) > 0, (pnPageNo - 1) * pnPageSize, 0);
  --
 EXPLAIN WITH vip_email AS (
    SELECT LOWER(jt.email COLLATE utf8mb4_unicode_ci) AS email
      FROM card_contact cc
      JOIN addressbooks ab ON cc.addressbookid = ab.id
      JOIN JSON_TABLE(
           CASE
             WHEN cc.email_text IS NULL OR cc.email_text = '' THEN '[]'
             ELSE CONCAT('["', REPLACE(TRIM(cc.email_text), ',', '","'), '"]')
           END
           ,'$[*]' COLUMNS (email VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci PATH '$')
    ) jt
    WHERE ab.uri = pvEmail
      AND cc.vip = 1
    ),
--     participant_match AS (
--     SELECT DISTINCT cm2.channel_id
--       FROM conference_member cm2
--      WHERE cm2.user_id <> pnUserId
--        AND cm2.revoke_time = 0
--        AND (
--            -- CASE 1: keyword supplied (alone OR WITH emails) -> regex MATCH
--            (bHasKeyword AND cm2.email RLIKE vKeyword2)
--         OR -- CASE 2: emails supplied (alone OR WITH keyword) -> email IN email_list
--            (bHasEmails AND EXISTS (
--                SELECT 1 FROM email_list el WHERE el.email = lower(cm2.email)
--              )
--            )
--         -- NOTE: CASE "BOTH" IS covered BY CASE 1 OR CASE 2 (no separate clause needed)
--         OR -- CASE 4: no keyword/email supplied -> RETURN ALL participants (so every channel matches)
--            (NOT bHasKeyword AND NOT bHasEmails)
--          )
--     ),
    vip_channel AS (
      SELECT cm.channel_id
        FROM conference_member cm
        JOIN vip_email ve ON cm.email = ve.email
       WHERE cm.revoke_time = 0
       GROUP BY cm.channel_id
      HAVING COUNT(DISTINCT cm.user_id) = 1
    ),
    email_list AS (
        SELECT LOWER(jt.email COLLATE utf8mb4_unicode_ci) AS email
        FROM JSON_TABLE(
            CASE WHEN pvEmails IS NULL THEN '[]'
                 ELSE pvEmails
            END,
            '$[*]' COLUMNS (email VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci PATH '$')
        ) jt
    ),
    ids_list AS (
        SELECT CAST(jt.val AS UNSIGNED) AS id
        FROM JSON_TABLE(
            CASE WHEN pvIDs IS NULL THEN '[]'
                 ELSE pvIDs
            END,
            '$[*]' COLUMNS(val VARCHAR(255) PATH '$')
        ) jt
    ),
    channel_uids_list AS (
        SELECT jt.val AS uid
        FROM JSON_TABLE(
            CASE WHEN pvChannelUIDs IS NULL THEN '[]'
                 ELSE pvChannelUIDs
            END,
            '$[*]' COLUMNS(val VARCHAR(255) PATH '$')
        ) jt
    ),
    channel_ids_list AS (
        SELECT CAST(jt.val AS UNSIGNED) AS id
        FROM JSON_TABLE(
            CASE WHEN pvChannelIDs IS NULL THEN '[]'
                 ELSE pvChannelIDs
            END,
            '$[*]' COLUMNS(val VARCHAR(255) PATH '$')
        ) jt
    ),
    collection_ids_list AS (
      SELECT CAST(jt.val AS UNSIGNED) AS id
      FROM JSON_TABLE(
             CASE WHEN pvCollectionIds IS NULL THEN '[]'
                  ELSE pvCollectionIds
             END,
             '$[*]' COLUMNS(val VARCHAR(255) PATH '$')
           ) jt
    )
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
        ,rculs.unread total_unread
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
          OR (EXISTS (
                SELECT 1
                  FROM collection co
                  WHERE cc.collection_id = co.id
                    AND co.is_trashed = 0
               )
             )
          )
      -- AND (cc.collection_id IS NULL OR co.is_trashed = 0)
      -- Collection NOT trashed
      AND cc.is_trashed = 0
      AND (cm.revoke_time = 0 -- NOT revoked
           OR (cm1.revoke_time > 0  -- revoked
               AND cm1.user_id = pnUserId -- ..but me
               AND ifnull(cc.collection_id, 0) = 0) -- ..NOT belongs TO shared channel
           )
      AND (cm1.revoke_time = 0 -- NOT revoked
            OR (cm1.revoke_time > 0  -- revoked
               AND cm1.user_id = pnUserId -- ..but me
               AND ifnull(cc.collection_id, 0) = 0) -- ..NOT belongs TO shared channel
          )
      AND (cm.updated_date < nModifiedLT    AND cc.updated_date < nModifiedLT)
      AND (cm.updated_date >= nModifiedGTE  OR cc.updated_date >= nModifiedGTE)
      AND (pnMinId IS NULL                  OR cm.id > pnMinId)
      AND (pnVip IS NULL                    OR cm.vip = pnVip)
      AND (pvIDs IS NULL OR cm.id IN (SELECT id FROM ids_list))
      AND (pvChannelUIDs IS NULL OR cc.uid IN (SELECT uid FROM channel_uids_list))
      AND (pvChannelIDs IS NULL OR cc.id IN (SELECT id FROM channel_ids_list))
      AND (pvCollectionIds IS NULL OR IF(pnFindBy = 1
                                         ,cc.collection_id IN (SELECT id FROM collection_ids_list)
                                         ,lco.collection_id IN (SELECT id FROM collection_ids_list)
                                        )
          )
      -- AND IF(pvCollectionIds IS NOT NULL, , 1)
      -- <> 1 - NOT GET channel belong TO collection
      AND IF(ifnull(pnIncludeShared, 0) = 1, 1, cc.collection_id IS NULL)
      -- value = 1 >> search BY channel name (keyword=channel name) 
      AND IF(nFilterType = 1, COALESCE(cm.title, cc.title, '') RLIKE vKeyword1, 1)
      -- value = 2 >> search BY participant 
      AND (nFilterType <> 2
        OR EXISTS (
           SELECT 1
             FROM conference_member cm2
            WHERE cm2.channel_id = cc.id
              AND cm2.user_id <> pnUserId
              AND cm2.revoke_time = 0
              AND (
                   -- CASE 1: keyword supplied (alone OR WITH emails) -> regex MATCH
                   (bHasKeyword AND cm2.email RLIKE vKeyword2)
                OR -- CASE 2: emails supplied (alone OR WITH keyword) -> email IN email_list
                   (bHasEmails AND EXISTS (
                       SELECT 1 FROM email_list el WHERE el.email = lower(cm2.email)
                     )
                   )
                -- NOTE: CASE "BOTH" IS covered BY CASE 1 OR CASE 2 (no separate clause needed)
                OR -- CASE 4: no keyword/email supplied -> RETURN ALL participants (so every channel matches)
                   (NOT bHasKeyword AND NOT bHasEmails)
                 )
--               AND CASE
--                      -- 1. email & keyword                 
--                      WHEN NOT isnull(pvKeyword) AND NOT isnull(pvEmails)
--                        THEN (cm2.email RLIKE vKeyword2 OR FIND_IN_SET(cm2.email, pvEmails))
--                      -- 2. email & keyword = blank
--                      WHEN isnull(pvKeyword) AND NOT isnull(pvEmails)
--                        THEN FIND_IN_SET(cm2.email, pvEmails)
--                      -- 3. email=blank & keyword
--                      WHEN NOT isnull(pvKeyword) AND isnull(pvEmails)
--                        THEN cm2.email RLIKE vKeyword2
--                      ELSE 1
--                      --
--                     END
          )
        )
      -- value = 3,4,5,6,7,8,9,10,11,12 >> search BY channel name || participant 
      AND (nFilterType NOT IN (3,4,5,6,7,8,9,10,11,12)
             -- search BY title
            OR IF(isnull(pvKeyword) AND NOT isnull(pvEmails)
               ,0
               ,COALESCE(cm.title, cc.title, '') RLIKE vKeyword1)
              -- search BY participant's emails
              OR EXISTS (
               SELECT 1
                 FROM conference_member cm2
                WHERE cm2.channel_id = cc.id
                  AND cm2.user_id <> pnUserId
                  AND cm2.revoke_time = 0
                  AND (
                   -- CASE 1: keyword supplied (alone OR WITH emails) -> regex MATCH
                   (bHasKeyword AND cm2.email RLIKE vKeyword2)
                OR -- CASE 2: emails supplied (alone OR WITH keyword) -> email IN email_list
                   (bHasEmails AND EXISTS (
                       SELECT 1 FROM email_list el WHERE el.email = lower(cm2.email)
                     )
                   )
                -- NOTE: CASE "BOTH" IS covered BY CASE 1 OR CASE 2 (no separate clause needed)
                OR -- CASE 4: no keyword/email supplied -> RETURN ALL participants (so every channel matches)
                   (NOT bHasKeyword AND NOT bHasEmails)
                 )
              )
          )
      -- value = 8: filter BY unread chat OR missed CALL
      -- value = 9 & relative (10,11,12): VIP
      AND (nFilterType NOT IN (4,7,8,9,10,11,12)
        OR CASE
          -- value = 4: filter BY missed CALL
          WHEN nFilterType = 4 
            THEN cm.missed_calls > 0
          -- value = 7: filter BY unread chat
          WHEN nFilterType = 7 
            THEN rculs.unread > 0
          -- value = 8: unread OR missed CALL
          WHEN nFilterType = 8 
            THEN (cm.missed_calls > 0 OR rculs.unread > 0)
          WHEN nFilterType IN (9,10,11,12)
            -- DEFAULT REQUIRE VIP
            THEN cc.id IN (SELECT channel_id FROM vip_channel)
                 AND (
                      -- value = 9: VIP ONLY
                      (nFilterType = 9)
                      -- value = 10: unread + VIP
                      OR (nFilterType = 10 AND rculs.unread > 0)
                      -- value = 11:  missed CALL + VIP
                      OR (nFilterType = 11 AND cm.missed_calls > 0)
                      -- value = 12: missed CALL + unread + VIP
                      OR (nFilterType = 12 AND cm.missed_calls > 0 AND rculs.unread > 0)
                     )
          ELSE 0
       END)
      GROUP BY cc.id, cm.id
      -- value = 5 >> 3 + only 1 participant
      HAVING nFilterType IN (1,2,3,4,7,8)
           -- VIP REQUIRE: only 2 member contained me
           OR (nFilterType IN (5,9,10,11,12)
              AND count(DISTINCT cm1.id) = 2) 
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
           WHEN NOT isnull(pnMinId)
             THEN cm.id
           WHEN NOT isnull(pnModifiedGTE)
             THEN GREATEST(cc.updated_date, cm.updated_date)
           --
         END) ASC
       --
       LIMIT pnPageSize
      OFFSET nOFFSET;
     --
    END