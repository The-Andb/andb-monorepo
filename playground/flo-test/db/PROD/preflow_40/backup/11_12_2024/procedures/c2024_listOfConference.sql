CREATE PROCEDURE `c2024_listOfConference`(pvKeyword       TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
                                                            ,pvEmails          TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
                                                            ,pnFilterType      TINYINT(1)
                                                            ,pnFindBy          TINYINT(1)
                                                            ,pvCollectionIds   TEXT 
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
  
  DECLARE nOFFSET     INT(11) DEFAULT 0;
  DECLARE vSort       VARCHAR(50) DEFAULT IF(IFNULL(pvSort, '') <> '' 
                                               AND NOT instr(pvSort, '-') 
                                               AND NOT instr(pvSort, '+'), concat('+', pvSort), ifnull(pvSort, '-start_time'));
  DECLARE vFieldSort  VARCHAR(50) DEFAULT REPLACE(REPLACE(IFNULL(vSort, ''), '-', ''), '+', '');
  DECLARE vKeyword    TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT ifnull(pvKeyword, '');
  DECLARE vKeyword1   TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
  DECLARE vKeyword2   TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
  DECLARE nFilterType TEXT DEFAULT ifnull(pnFilterType, 1);
  
  SET vKeyword1 = CONCAT('( ',vKeyword,')|(^',vKeyword,')');
  
  SET vKeyword2 = CONCAT('( ',vKeyword,')|(^',vKeyword,')|(@',vKeyword,')');
  
  SET nOFFSET = IF(ifnull(pnPageNo, 0) > 0, (pnPageNo - 1) * pnPageSize, 0);
  
  SELECT cm.id, ifnull(cc.collection_id, 0) collection_id, cm.channel_id, cc.uid, cm.email, cm.is_creator, cm.description
        ,cm.vip, cm.revoke_time, greatest(cm.updated_date, cc.updated_date) updated_date, cm.created_date, cm.join_time
        ,ifnull(cm.view_chat_history, 1) view_chat_history
        
        ,cc.room_url, ifnull(cc.enable_chat_history, 1) enable_chat_history
        ,COALESCE(cm.title, cc.title, '') title
        ,cc.title share_title
        ,ch.start_time, ch.end_time, ch.action_time, ch.status, ch.type
        ,cc.last_used
        ,cc.realtime_channel
     FROM conference_channel cc
     JOIN conference_member cm ON (cm.channel_id = cc.id)
LEFT JOIN conference_history ch ON (cm.id = ch.member_id AND cm.user_id = ch.user_id AND ch.id = cm.last_history_id)
LEFT JOIN conference_member cm1 ON (cc.id = cm1.channel_id)
LEFT JOIN linked_collection_object lco ON (cc.uid = lco.object_uid 
                                           AND cm.user_id = lco.user_id 
                                           AND lco.object_type = 'CONFERENCING' 
                                           AND ifnull(lco.is_trashed, 0) = 0
                                           )

    WHERE cm.user_id = pnUserId
      AND (cm.revoke_time = 0 
           OR (cm1.revoke_time > 0  
               AND cm1.user_id = pnUserId 
               AND ifnull(cc.collection_id, 0) = 0) 
           )
      
      
      AND cc.is_trashed = 0
      AND (cm1.revoke_time = 0 
            OR (cm1.revoke_time > 0  
               AND cm1.user_id = pnUserId 
               AND ifnull(cc.collection_id, 0) = 0) 
          )
      AND (
          cm.updated_date < IF(ifnull(pnModifiedLT, 0) > 0, pnModifiedLT, unix_timestamp() + 1)
          OR
          cc.updated_date < IF(ifnull(pnModifiedLT, 0) > 0, pnModifiedLT, unix_timestamp() + 1)
          )
      AND (
          cm.updated_date >= IF(ifnull(pnModifiedGTE, 0) > 0, pnModifiedGTE, 0)
          OR
          cc.updated_date >= IF(ifnull(pnModifiedGTE, 0) > 0, pnModifiedGTE, 0)
          )
      AND (pnMinId IS NULL         OR cm.id > pnMinId)
      AND (pnVip IS NULL           OR cm.vip = pnVip)
      AND (pvIDs IS NULL           OR FIND_IN_SET(cm.id, pvIDs))
      AND (pvChannelUIDs IS NULL   OR FIND_IN_SET(cc.uid, pvChannelUIDs))
      AND (pvChannelIDs IS NULL    OR FIND_IN_SET(cc.id, pvChannelIDs))
      AND (pvCollectionIds IS NULL 
           OR IF(pnFindBy = 1
                ,FIND_IN_SET(cc.collection_id, pvCollectionIds) 
                ,FIND_IN_SET(lco.collection_id, pvCollectionIds) 
                )
          )
      
      
      AND IF(ifnull(pnIncludeShared, 0) = 1, 1, cc.collection_id IS NULL)
      
      AND IF(nFilterType = 1, COALESCE(cm.title, cc.title, '') RLIKE vKeyword1, 1)
      
      AND IF(nFilterType <> 2, 1, EXISTS (
            SELECT 1
              FROM conference_member cm2
             WHERE cm2.channel_id = cc.id
               AND cm2.user_id <> pnUserId
               AND cm2.revoke_time = 0
               AND CASE
                     
                     WHEN NOT isnull(pvKeyword) AND NOT isnull(pvEmails)
                       THEN (cm2.email RLIKE vKeyword2 OR FIND_IN_SET(cm2.email, pvEmails))
                     
                     WHEN isnull(pvKeyword) AND NOT isnull(pvEmails)
                       THEN FIND_IN_SET(cm2.email, pvEmails)
                     
                     WHEN NOT isnull(pvKeyword) AND isnull(pvEmails)
                       THEN cm2.email RLIKE vKeyword2
                     ELSE 1
                     
                    END
         ))
      
      AND (IF(nFilterType IN (3,4,5,6)
           
          ,IF(isnull(pvKeyword) AND NOT isnull(pvEmails)
             ,0
             ,COALESCE(cm.title, cc.title, '') RLIKE vKeyword1)
          
          OR EXISTS (
             SELECT 1
               FROM conference_member cm2
              WHERE cm2.channel_id = cc.id
                AND cm2.user_id <> pnUserId
                AND cm2.revoke_time = 0
                AND CASE
                      
                      WHEN NOT isnull(pvKeyword) AND NOT isnull(pvEmails)
                        THEN (cm2.email RLIKE vKeyword2 OR FIND_IN_SET(cm2.email, pvEmails))
                      
                      WHEN isnull(pvKeyword) AND NOT isnull(pvEmails)
                        THEN FIND_IN_SET(cm2.email, pvEmails)
                      
                      WHEN NOT isnull(pvKeyword) AND isnull(pvEmails)
                        THEN cm2.email RLIKE vKeyword2
                     ELSE 1
                      
                     END
         ), 1)
        )
        
        
        AND IF(nFilterType = 4
            ,cm.missed_calls > 0
             OR (ch.status IN (23, 24, 25) AND ch.end_time > 0)
             ,1)
        
      GROUP BY cc.id, cm.id, cm1.channel_id
      
      HAVING nFilterType < 5 
           OR (nFilterType = 5 
              AND count(DISTINCT cm1.id) = 2) 
           
           OR (nFilterType = 6 
              AND count(lco.id) = 0) 
      ORDER BY
        (CASE
           
           WHEN NOT isnull(pnModifiedLT) AND isnull(pnPageNo) 
              THEN GREATEST(cc.updated_date, cm.updated_date)
           WHEN ifnull(pnPageNo, 0) > 0 AND INSTR(vSort, "-") 
             THEN 
             
             CASE vFieldSort
               
               WHEN 'start_time'   THEN GREATEST(ifnull(ch.updated_date, 0), cc.created_date, ifnull(cc.last_used, 0))
               WHEN 'action_time'  THEN ch.action_time
               WHEN 'created_date' THEN cm.created_date
               WHEN 'title'        THEN ifnull(cm.title, cc.title)
               WHEN 'last_call'    THEN GREATEST(ifnull(ch.updated_date, 0), cc.created_date)
               WHEN 'last_chat'    THEN GREATEST(ifnull(cc.last_used, 0), cc.created_date) 
               
             END
           
         END) DESC,
        (CASE
           
           WHEN NOT isnull(pnMinId) THEN cm.id
           WHEN NOT isnull(pnModifiedGTE) AND isnull(pnPageNo)
             THEN GREATEST(cc.updated_date, cm.updated_date)
           WHEN ifnull(pnPageNo, 0) > 0 AND INSTR(vSort, "+") THEN
             
             CASE vFieldSort 
               
               WHEN 'start_time'   THEN GREATEST(ifnull(ch.updated_date, 0), cc.created_date, ifnull(cc.last_used, 0))
               WHEN 'action_time'  THEN ch.action_time
               WHEN 'created_date' THEN cm.created_date
               WHEN 'title'        THEN ifnull(cm.title, cc.title)
               WHEN 'last_call'    THEN GREATEST(ifnull(ch.updated_date, 0), cc.created_date)
               WHEN 'last_chat'    THEN GREATEST(ifnull(cc.last_used, 0), cc.created_date) 
               
              END
           
         END) ASC
       
       LIMIT pnPageSize
      OFFSET nOFFSET;
     
    END