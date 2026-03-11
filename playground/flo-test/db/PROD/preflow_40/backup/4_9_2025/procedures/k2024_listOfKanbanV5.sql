CREATE PROCEDURE `k2024_listOfKanbanV5`(pvIds         TEXT
                                                        ,pvCollectionIds TEXT
                                                        ,pnCollectionId  BIGINT(20)
                                                        ,pnUserId        BIGINT(20)
                                                        ,pvUsername      VARCHAR(100)
                                                        ,pbIsArchive     TINYINT(1)
                                                        ,pnModifiedGTE   DOUBLE(14,4)
                                                        ,pnModifiedLT    DOUBLE(14,4)
                                                        ,pnMinId         BIGINT(20)
                                                        ,pnPageSize      INTEGER(11)
                                                        ,pnPageNo        INTEGER(11)
                                                        ,pnIncludeShared TINYINT(1)
                                                        ,pvSort          VARCHAR(128)
                                                        ,pnIncludeTodoStatus TINYINT(1))
BEGIN
  --
  DECLARE nPageNo         INT(11) DEFAULT ifnull(pnPageNo, 0);
  DECLARE nOFFSET         INT(11) DEFAULT 0;
  DECLARE vFieldSort      VARCHAR(50) DEFAULT REPLACE(REPLACE(IFNULL(pvSort, ''), '-', ''), '+', '');                                              
  DECLARE vSort           VARCHAR(50) DEFAULT IF(IFNULL(pvSort, '') <> '' -- DEFAULT +: ASC
                                    AND NOT instr(pvSort, '-') 
                                    AND NOT instr(pvSort, '+'), concat('+', pvSort), pvSort);
  DECLARE vTodoStatusName TEXT DEFAULT 'Status for ToDo\'s';
  --
  IF ifnull(pvSort, 'NA') <> 'NA' THEN
    --
    SET nOFFSET = IF(ifnull(pnPageNo, 0) = 0, 0, (pnPageNo - 1) * pnPageSize);
    --
  END IF;
  --
  SELECT kk.id, kk.collection_id, kk.name, kk.color, kk.user_id
        ,kk.order_number, COALESCE(ki.archive_status, kk.archive_status, 0) archive_status, kk.order_update_time, kk.show_done_todo
        ,kk.add_new_obj_type, COALESCE(ki.sort_by_type, kk.sort_by_type, 0) sort_by_type, COALESCE(ki.archived_time, kk.archived_time, 0) archived_time, kk.kanban_type, kk.is_trashed
        ,kk.created_date
        ,greatest(ifnull(ki.updated_date, 0), kk.updated_date) updated_date
     FROM kanban kk
LEFT JOIN kanban_instance ki ON (ki.kanban_id = kk.id AND ki.user_id = pnUserId)
     JOIN collection co ON (kk.collection_id = co.id)
     JOIN (
         -- owner existed collection_id
          SELECT co.id collection_id, co.calendar_uri owner_calendar_uri, co.user_id owner_user_id
                ,'' member_calendar_uri, '' member_email
                ,0 member_user_id
                ,usr.username owner_username
            FROM collection co
            JOIN user usr ON (co.user_id = usr.id)
           WHERE IF(NOT ISNULL(pvCollectionIds), FIND_IN_SET(co.id, pvCollectionIds), 1)
             AND (pnCollectionId IS NULL OR co.id = pnCollectionId)
            -- AND (co.`type` = 3 OR (pnCollectionId > 0 OR pvObjectUid <> '')) -- owner GET BY uid? dont need TO share
             AND co.user_id = pnUserId
             AND co.is_trashed = 0
          UNION
          -- member existed collection_id
          SELECT co.id collection_id, co.calendar_uri owner_calendar_uri, co.user_id owner_user_id
                ,csm.calendar_uri member_calendar_uri, csm.shared_email member_email
                ,csm.member_user_id
                ,usr.username owner_username
            FROM collection co
            JOIN user usr ON (co.user_id = usr.id)
            JOIN collection_shared_member csm ON (csm.collection_id = co.id AND csm.shared_status = 1)
           WHERE IF(NOT ISNULL(pvCollectionIds), FIND_IN_SET(co.id, pvCollectionIds), 1)
             AND (pnCollectionId IS NULL OR co.id = pnCollectionId)
             AND co.is_trashed = 0
             AND csm.member_user_id = pnUserId
             AND co.type = 3 -- share only
            ) permistion ON (permistion.collection_id = kk.collection_id
            AND (kk.user_id = permistion.owner_user_id OR kk.user_id = permistion.member_user_id))
      
   WHERE IF(NOT ISNULL(pvIds), FIND_IN_SET(kk.id, pvIds), 1)
     -- <> 1 - NOT GET shared kanban
     AND IF(ifnull(pnIncludeShared, 0) = 1, 1, kk.kanban_type <> 3)
     -- AND co.id = IFNULL(pnCollectionId, co.id)
     AND (pnCollectionId IS NULL OR co.id = pnCollectionId)
     AND IF(NOT ISNULL(pvCollectionIds), FIND_IN_SET(co.id, pvCollectionIds), 1)
     AND co.is_trashed = 0
     AND kk.is_trashed = 0
     AND (kk.kanban_type    = 3 OR (kk.kanban_type IN (0, 1) AND kk.user_id = pnUserId))
     AND (kk.updated_date    < IF(IFNULL(pnModifiedLT, 0) > 0, pnModifiedLT, unix_timestamp() + 1)
            OR ki.updated_date    < IF(IFNULL(pnModifiedLT, 0) > 0, pnModifiedLT, unix_timestamp() + 1)
         )
     AND (kk.updated_date    >= IF(IFNULL(pnModifiedGTE, 0) > 0, pnModifiedGTE, 0)
           OR  ki.updated_date    >= IF(IFNULL(pnModifiedGTE, 0) > 0, pnModifiedGTE, 0)
         )
     AND kk.id > IF(IFNULL(pnMinId, 0) > 0, pnMinId, 0)
     AND IF(IFNULL(pnIncludeTodoStatus, 0) = 1, 1, NOT (kk.kanban_type = 1 AND kk.name = vTodoStatusName))
   GROUP BY kk.id
   ORDER BY
        (CASE
           --
           WHEN isnull(pnMinId) AND INSTR(vSort, "-") THEN
             --
             CASE vFieldSort
               --
               WHEN 'order_number' THEN kk.order_number            
               WHEN 'updated_date' THEN kk.updated_date
               --
             END
           WHEN NOT isnull(pnModifiedLT) AND isnull(pnModifiedGTE) THEN kk.updated_date
           --
         END) DESC,
        (CASE
           --
           WHEN isnull(pnMinId) AND INSTR(vSort, "+") THEN
             --
             CASE vFieldSort 
               --
               WHEN 'order_number' THEN kk.order_number             
               WHEN 'updated_date' THEN kk.updated_date
               --
              END
           WHEN NOT isnull(pnMinId) THEN kk.id
           WHEN NOT isnull(pnModifiedGTE) THEN kk.updated_date
           --
         END) ASC
         --
   LIMIT pnPageSize
  OFFSET nOFFSET;
--
END