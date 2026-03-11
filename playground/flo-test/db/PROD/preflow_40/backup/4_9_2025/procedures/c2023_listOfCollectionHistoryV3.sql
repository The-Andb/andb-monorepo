CREATE PROCEDURE `c2023_listOfCollectionHistoryV3`(pnCollectionId    BIGINT(20)
                                                                 ,pvObjectUid     VARBINARY(1000)
                                                                 ,pnUserId        BIGINT(20)
                                                                 ,pvIDs           TEXT
                                                                 ,pnModifiedGTE   DOUBLE(14,4)
                                                                 ,pnModifiedLT    DOUBLE(14,4)
                                                                 ,pnMinId         BIGINT(20)
                                                                 ,pnPageSize      INTEGER(11)
                                                                 ,pnPageNo        INTEGER(11)
                                                                 ,pvSort          VARCHAR(128)
                                                                 ,pnIncludeShared TINYINT(1))
BEGIN
  -- 
  DECLARE nPageNo           INT(11) DEFAULT ifnull(pnPageNo, 0);
  DECLARE nCollectionId     INT(11) DEFAULT ifnull(pnCollectionId, 0);
  DECLARE vObjectUid        VARBINARY(1000) DEFAULT ifnull(pvObjectUid, '');
  DECLARE nOFFSET           INT(11)   DEFAULT 0;
  DECLARE nModifiedLT       DOUBLE(14,4) DEFAULT ifnull(pnModifiedLT, 0);
  DECLARE nModifiedGTE      DOUBLE(14,4) DEFAULT ifnull(pnModifiedGTE, 0);
  DECLARE vFieldSort        VARCHAR(50) DEFAULT REPLACE(REPLACE(IFNULL(pvSort, ''), '-', ''), '+', '');
 -- DEFAULT IS ASC
  DECLARE vSort        VARCHAR(50) DEFAULT IF(IFNULL(pvSort, '') <> '' 
                                               AND NOT instr(pvSort, '-') 
                                               AND NOT instr(pvSort, '+'), concat('+', pvSort), pvSort);
  --
  IF ifnull(pvSort, 'NA') <> 'NA' THEN
    --
    SET nOFFSET = IF(nPageNo > 0, (nPageNo - 1) * pnPageSize, 0);
    --
  END IF;
  --
  SELECT his.id, his.collection_activity_id, his.email, his.action, his.action_time, his.content
        ,his.created_date, his.updated_date, his.assignees, his.kanban_id
        ,his.collection_id, his.object_uid, his.object_type, IF(his.object_type = 'URL', '', his.object_href) object_href
        ,his.member_calendar_uri, his.member_email, his.member_user_id
        ,his.owner_user_id, his.owner_calendar_uri, his.owner_username, his.owner_user_id
    FROM (
          -- owner existed collection_id
          SELECT ch.id, ch.collection_activity_id, ch.email, ch.action, ch.action_time, ch.content
                ,ch.created_date, ch.updated_date, ch.assignees, ch.kanban_id
                ,ca.object_uid, ca.object_type, IF(ca.object_type = 'URL', '', ca.object_href) object_href
                ,co.id collection_id, co.calendar_uri owner_calendar_uri, co.user_id owner_user_id
                ,'' member_calendar_uri, '' member_email, 0 member_user_id
                ,usr.username owner_username
            FROM collection_history ch
            JOIN collection_activity ca ON (ch.collection_activity_id = ca.id)
            JOIN collection co ON (ca.collection_id = co.id)
            JOIN user usr ON (co.user_id = usr.id)
           WHERE co.id = IF(nCollectionId > 0, nCollectionId, co.id)
             AND co.`type` = IF(nCollectionId > 0 OR vObjectUid <> '', co.`type`, 3) -- owner GET BY uid? dont need TO share
             AND co.user_id = pnUserId
             AND ca.object_type <> 'KANBAN'
          UNION
          SELECT ch.id, ch.collection_activity_id, ch.email, ch.action, ch.action_time, ch.content
                ,ch.created_date, ch.updated_date, ch.assignees, ch.kanban_id
                ,ca.object_uid, ca.object_type, IF(ca.object_type = 'URL', '', ca.object_href) object_href
                ,co.id collection_id, co.calendar_uri owner_calendar_uri, co.user_id owner_user_id
                ,csm.calendar_uri member_calendar_uri, csm.shared_email member_email, csm.member_user_id
                ,usr.username owner_username
            FROM collection_history ch
            JOIN collection_activity ca ON (ch.collection_activity_id = ca.id)
            JOIN collection co ON (ca.collection_id = co.id)
            JOIN user usr ON (co.user_id = usr.id)
            JOIN collection_shared_member csm ON (csm.collection_id = co.id AND csm.shared_status = 1)
           WHERE (nCollectionId = 0 OR co.id = nCollectionId)
           AND ca.object_type <> 'KANBAN'
             AND co.is_trashed = 0
             -- AND lco.is_trashed = 0
             AND csm.member_user_id = pnUserId
             AND co.type = 3 -- share only
          -- kanban
          UNION
          SELECT ch.id, ch.collection_activity_id, ch.email, ch.action, ch.action_time, ch.content
                ,ch.created_date, ch.updated_date, ch.assignees, ch.kanban_id
                ,ca.object_uid, ca.object_type, '' object_href
                ,co.id collection_id, co.calendar_uri owner_calendar_uri, co.user_id owner_user_id
                ,'' member_calendar_uri, '' member_email, 0 member_user_id
                ,usr.username owner_username
            FROM collection_history ch
            JOIN collection_activity ca ON (ch.collection_activity_id = ca.id)
            JOIN collection co ON (ca.collection_id = co.id)
            JOIN collection_shared_member csm ON (csm.collection_id = co.id AND csm.shared_status = 1)
            JOIN user usr ON (co.user_id = usr.id)
           WHERE (nCollectionId = 0 OR co.id = nCollectionId)
             AND csm.member_user_id = pnUserId
             AND ca.object_type = 'KANBAN'
             AND co.is_trashed = 0
             AND co.type = 3 -- share only
             
          -- omni
           UNION
          SELECT ch.id, ch.collection_activity_id, ch.email, ch.action, ch.action_time, ch.content
                ,ch.created_date, ch.updated_date, ch.assignees, ch.kanban_id
                ,ca.object_uid, ca.object_type, IF(ca.object_type = 'URL', '', ca.object_href) object_href
                ,0 collection_id, '' owner_calendar_uri, pnUserId owner_user_id
                ,'' member_calendar_uri, '' member_email, 0 member_user_id
                ,'' owner_username
            FROM collection_history ch
            JOIN collection_activity ca ON (ch.collection_activity_id = ca.id)
           WHERE ca.collection_id = 0
           AND ca.object_type <> 'KANBAN'
           AND ca.user_id = pnUserId
            ) his
   WHERE his.collection_id = IF(nCollectionId > 0, nCollectionId, his.collection_id)
     AND his.object_uid = IF(vObjectUid <> '', vObjectUid, his.object_uid)
     AND his.updated_date < IF(nModifiedLT > 0, nModifiedLT, unix_timestamp() + 1)
     AND his.updated_date >= IF(nModifiedGTE > 0, nModifiedGTE, 0)
     AND his.id > IF(ifnull(pnMinId, 0) > 0, pnMinId, 0)
     AND IF(ifnull(pvIDs,'NA' <>'NA'), FIND_IN_SET(his.id, pvIDs), 1)
     -- <> 1 - NOT GET shared kanban
     -- AND IF(ifnull(pnIncludeShared, 0) = 1, 1, ch.`action` NOT IN (20,21,22))
   GROUP BY his.id
    ORDER BY 
         --
         (CASE WHEN ifnull(vSort,'') <> '' THEN
               CASE WHEN INSTR(vSort, "-") THEN
                  CASE vFieldSort 
                    WHEN 'action_time' THEN his.action_time
                    WHEN 'updated_date' THEN his.updated_date
                    WHEN 'created_date' THEN his.created_date
                 END
                END
               WHEN nModifiedLT > 0 THEN his.updated_date
           --
           END) DESC,
        (CASE WHEN ifnull(vSort,'') <> '' THEN
              CASE WHEN INSTR(vSort, "+") THEN
                 CASE vFieldSort 
                    WHEN 'action_time' THEN his.action_time
                    WHEN 'updated_date' THEN his.updated_date
                    WHEN 'created_date' THEN his.created_date
                 END
              END
              WHEN nModifiedGTE > 0 THEN his.updated_date 
              WHEN ifnull(pnMinId, 0) > 0 THEN his.id
             -- ELSE ch.id
          END) ASC
         --
   LIMIT pnPageSize
  OFFSET nOFFSET;
--
END