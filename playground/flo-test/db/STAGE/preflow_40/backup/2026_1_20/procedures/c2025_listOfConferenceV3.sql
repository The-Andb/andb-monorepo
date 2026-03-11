CREATE PROCEDURE `c2025_listOfConferenceV3`(
 pvKeyword         TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
,pvEmails          TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci -- REQUIRE JSON format: ["abc@xzy.com",..]
,pnFilterType      TINYINT(2)
,pnFindBy          TINYINT(1) -- find link only
,pvCollectionIds   JSON -- find link only
,pvChannelIDs      JSON
,pvChannelUIDs     JSON
,pvIDs             JSON
,pnModifiedGTE     DOUBLE(14,4)
,pnModifiedLT      DOUBLE(14,4)
,pnMinId           BIGINT(20)
,pnVip             TINYINT(1)
,pnPageSize        INTEGER(11)
,pnPageNo          INTEGER(11)
,pvSort            VARCHAR(128)
,pnIncludeShared   TINYINT(1)
,pnApplySetting    TINYINT(1)
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
  DECLARE nApplySetting   TINYINT(1) DEFAULT ifnull(pnApplySetting,0);

  -- UPDATE for MySQL 8.0+
  SET @raw_kw = IFNULL(pvKeyword, '');
  --
  SET vKeyword = REGEXP_REPLACE(
                 @raw_kw,
                 '([\\^.$|?*+()\\[\\]{}\\\\])',
                 '\\\\$1');
  -- Determine IF the keyword contains "letters/numbers" OR just punctuation
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
  WITH vip_email AS (
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
        ,IF(cm.notification_call = 0, 0, cm.last_missed_call) last_missed_call
        ,IF(cm.notification_call = 0, 0, cm.missed_calls) missed_calls
        ,IF(nApplySetting = 0, rculs.unread
        ,CASE
              WHEN cm.notification_chat = 0 THEN 0
              WHEN cm.notification_chat = 1 THEN rculs.mentioned_from_last_seen
              WHEN cm.notification_chat = 2 THEN rculs.unread
              ELSE 0
            END) total_unread
         ,c2025_conditionSort4Conference(ch.updated_date
                                         ,cm.created_date
                                         ,cc.last_used
                                         ,rculs.channel_last_message_created_date
                                         ,cm.last_missed_call
                                         ,nFilterType
                                         ,nApplySetting
                                         ,cm.notification_call) last_activity
     FROM conference_channel cc
     JOIN conference_member cm ON (cm.channel_id = cc.id)
     JOIN `user` u ON (u.id = cm.user_id)
     JOIN realtime_channel rc ON (rc.type = 'CONFERENCE' AND cc.id = rc.internal_channel_id)
     JOIN realtime_channel_member rcm ON (rc.id = rcm.channel_id AND rcm.email = u.email)
LEFT JOIN (
      SELECT cm2.channel_id
            ,(cm2.channel_id IS NOT NULL) AS is_vip
        FROM vip_email ve
        JOIN conference_member cm2 ON (cm2.email = ve.email)
       WHERE nFilterType IN (9, 10, 11, 12)
         AND cm2.revoke_time = 0
         AND cm2.user_id <> pnUserId
         AND (pvChannelIDs IS NULL 
              OR cm2.channel_id IN (SELECT id FROM channel_ids_list)
             )
       GROUP BY cm2.channel_id
      HAVING COUNT(DISTINCT cm2.user_id) = 1
    ) vc ON (vc.channel_id = cc.id)
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
      AND greatest(cm.updated_date, cc.updated_date) < nModifiedLT
      AND greatest(cm.updated_date, cc.updated_date) >= nModifiedGTE
      AND (pnMinId IS NULL                  OR cm.id > pnMinId)
      AND (pvIDs IS NULL                    OR cm.id IN (SELECT id FROM ids_list))
      AND (pvChannelUIDs IS NULL            OR cc.uid IN (SELECT uid FROM channel_uids_list))
      AND (pvChannelIDs IS NULL             OR cc.id IN (SELECT id FROM channel_ids_list))
      AND (pvCollectionIds IS NULL          OR IF(pnFindBy = 1
                                                  -- find BY channel
                                                  ,cc.collection_id IN (SELECT id FROM collection_ids_list)
                                                  -- find BY link
                                                  ,lco.collection_id IN (SELECT id FROM collection_ids_list)
                                                 ))
      -- AND IF(pvCollectionIds IS NOT NULL, , 1)
      -- <> 1 - NOT GET channel belong TO collection
      AND (ifnull(pnIncludeShared, 0) = 1   OR cc.collection_id IS NULL)
      -- value = 1 >> search BY channel name (keyword=channel name) 
      AND (nFilterType <> 1                 
           OR (pvKeyword IS NULL 
               OR COALESCE(cm.title, cc.title, '') LIKE CONCAT('%', pvKeyword, '%')
              )
           OR COALESCE(cm.title, cc.title, '') RLIKE vKeyword1
          )
      -- value = 2 >> search BY participant 
      AND (nFilterType <> 2
           OR EXISTS (SELECT 1
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
      -- How TO USE keyword?  
      -- value = 3,4,5,6,7,8,9,10,11,12 >> search BY channel name || participant 
      AND (nFilterType NOT IN (3,4,5,6,7,8,9,10,11,12)
             -- search BY title
            OR IF(isnull(pvKeyword) AND NOT isnull(pvEmails)
               ,0
               ,(pvKeyword IS NULL 
                 OR COALESCE(cm.title, cc.title, '') LIKE CONCAT('%', pvKeyword, '%')
                )
                OR COALESCE(cm.title, cc.title, '') RLIKE vKeyword1
              )
              -- search BY participant's emails
              OR EXISTS (
               SELECT 1
                 FROM conference_member cm2
                WHERE cm2.channel_id = cc.id
                  AND cm2.user_id <> pnUserId
                  AND cm2.revoke_time = 0
                  AND (
                   -- CASE 1: keyword supplied (alone OR WITH emails) -> regex MATCH
                   (bHasKeyword AND (
                      cm2.email LIKE CONCAT('%', pvKeyword, '%')
                      OR cm2.email RLIKE vKeyword2
                    )
                   )
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
      -- How TO apply manual VIP
       AND IF(nFilterType IN (9, 10, 11, 12), 1, pnVip IS NULL OR cm.vip = pnVip)
      -- How TO apply action for filter CALL, chat?
      AND (
          nFilterType NOT IN (4, 7, 8, 9, 10, 11, 12)
          OR (
            -- 1. VIP CHECK: Auto VIP (vip_channel) for filterType 9,10,11,12
            (nFilterType NOT IN (9, 10, 11, 12)
              -- auto
              OR IFNULL(vc.is_vip, 0) = 1
              -- manual
              OR (pnVip IS NOT NULL AND cm.vip = pnVip)    
            ) 
            -- 2. Apply setting CHECK
            AND (
              nApplySetting = 0
              OR nFilterType = 9
              OR (pnVip IS NOT NULL AND cm.vip = pnVip)
              OR (nFilterType IN (4, 8, 11, 12) AND cm.notification_call = 1)
              OR (nFilterType IN (7, 8, 10, 12) AND cm.notification_chat IN (1, 2))
            )
            -- 3. Pure data conditions
            AND (nFilterType = 9 
             OR CASE
                  -- 4 & 11 → missed CALL filters
                  WHEN nFilterType IN (4, 11) THEN cm.missed_calls > 0
                  -- 7 & 10 → unread message filters
                  WHEN nFilterType IN (7, 10) THEN CASE
                                    --
                                    WHEN nApplySetting = 0 OR cm.notification_chat = 2
                                      THEN rculs.unread > 0
                                    WHEN cm.notification_chat = 1 
                                      THEN rculs.mentioned_from_last_seen > 0
                                    ELSE 0
                                    --
                                  END
                  -- 8 & 12 → unread OR missed CALL filters
                  WHEN nFilterType IN (8, 12) THEN cm.missed_calls > 0 
                      OR (CASE
                            --
                            WHEN nApplySetting = 0 OR cm.notification_chat = 2 
                              THEN rculs.unread > 0
                            WHEN cm.notification_chat = 1 
                              THEN rculs.mentioned_from_last_seen > 0
                            ELSE 0
                            --
                          END)
                  ELSE 0
                  --
                END)
          )
        )
      GROUP BY cc.id, cm.id
      HAVING nFilterType IN (1,2,3,4,7,8)
           -- VIP contact: only 2 member contained me
           OR (nFilterType IN (5,9,10,11,12)
              AND count(DISTINCT cm1.id) = 2)
           -- VIP manual
           OR (pnVip IS NOT NULL AND cm.vip = pnVip)
           -- value = 6: No Collection
           OR (nFilterType = 6 
              AND count(lco.id) = 0) -- no collection
      ORDER BY 
          (CASE
             WHEN vSort IS NOT NULL AND INSTR(vSort, "-") 
               THEN -- DEFAULT WHEN no ASC active
               CASE vFieldSort
                 WHEN 'start_time' 
                   THEN c2025_conditionSort4Conference(ch.updated_date
                                                      ,cm.created_date
                                                      ,cc.last_used
                                                      ,rculs.channel_last_message_created_date
                                                      ,cm.last_missed_call
                                                      ,nFilterType
                                                      ,nApplySetting
                                                      ,cm.notification_call)
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
                 THEN c2025_conditionSort4Conference(ch.updated_date
                                                    ,cm.created_date
                                                    ,cc.last_used
                                                    ,rculs.channel_last_message_created_date
                                                    ,cm.last_missed_call
                                                    ,nFilterType
                                                    ,nApplySetting
                                                    ,cm.notification_call)
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