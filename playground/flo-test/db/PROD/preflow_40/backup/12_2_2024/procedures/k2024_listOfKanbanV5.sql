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
                                                        ,pvSort          VARCHAR(128))
BEGIN
  --
  DECLARE nPageNo         INT(11) DEFAULT ifnull(pnPageNo, 0);
  DECLARE nOFFSET         INT(11) DEFAULT 0;
  DECLARE vFieldSort      VARCHAR(50) DEFAULT REPLACE(REPLACE(IFNULL(pvSort, ''), '-', ''), '+', '');                                              
  DECLARE vSort           VARCHAR(50) DEFAULT IF(IFNULL(pvSort, '') <> '' -- DEFAULT +: ASC
                                    AND NOT instr(pvSort, '-') 
                                    AND NOT instr(pvSort, '+'), concat('+', pvSort), pvSort);
  --
  IF ifnull(pvSort, 'NA') <> 'NA' THEN
    --
    SET nOFFSET = IF(ifnull(pnPageNo, 0) = 0, 0, (pnPageNo - 1) * pnPageSize);
    --
  END IF;
  --
 EXPLAIN SELECT kb.id, kb.collection_id, kb.name, kb.color, kb.user_id
        ,kb.order_number, COALESCE(ki.archive_status, kb.archive_status, 0) archive_status, kb.order_update_time, kb.show_done_todo
        ,kb.add_new_obj_type, kb.sort_by_type, COALESCE(ki.archived_time, kb.archived_time, 0) archived_time, kb.kanban_type, kb.is_trashed
        ,kb.created_date
        ,greatest(ifnull(ki.updated_date, 0), kb.updated_date) updated_date
     FROM kanban kb
LEFT JOIN kanban_instance ki ON (ki.kanban_id = kb.id AND ki.user_id = pnUserId)
     JOIN collection co ON (kb.collection_id = co.id)
LEFT JOIN collection_shared_member csm ON (co.id = csm.collection_id)
   WHERE (
             ( -- owner collection WITH shared kanban
              kb.kanban_type = 3 -- shared
              AND (
                   co.user_id = pnUserId 
                   OR ( -- editor WITH shared kaban
                       csm.member_user_id = pnUserId 
                   AND csm.shared_status = 1 -- joined
                      )
                  )
             )
             OR (  -- owner kanban without shared kanban
                 kb.kanban_type <> 3
             AND kb.user_id = pnUserId
                )
            )
     AND (pvIds IS NULL OR FIND_IN_SET(kb.id, pvIds))
     -- <> 1 - NOT GET shared kanban
     AND IF(ifnull(pnIncludeShared, 0) = 1, 1, kb.kanban_type <> 3)
     -- AND co.id = IFNULL(pnCollectionId, co.id)
     AND (pnCollectionId IS NULL OR co.id = pnCollectionId)
     AND IF(NOT ISNULL(pvCollectionIds), FIND_IN_SET(co.id, pvCollectionIds), 1)
     AND co.is_trashed = 0
     AND (kb.kanban_type    = 3 OR (kb.kanban_type IN (0, 1) AND kb.user_id = pnUserId))
     AND (kb.updated_date    < IF(IFNULL(pnModifiedLT, 0) > 0, pnModifiedLT, unix_timestamp() + 1)
            OR ki.updated_date    < IF(IFNULL(pnModifiedLT, 0) > 0, pnModifiedLT, unix_timestamp() + 1)
         )
     AND (kb.updated_date    >= IF(IFNULL(pnModifiedGTE, 0) > 0, pnModifiedGTE, 0)
           OR  ki.updated_date    >= IF(IFNULL(pnModifiedGTE, 0) > 0, pnModifiedGTE, 0)
         )
     AND kb.id > IF(IFNULL(pnMinId, 0) > 0, pnMinId, 0)
   GROUP BY kb.id
   ORDER BY
        (CASE
           --
           WHEN isnull(pnMinId) AND INSTR(vSort, "-") THEN
             --
             CASE vFieldSort
               --
               WHEN 'order_number' THEN kb.order_number            
               WHEN 'updated_date' THEN kb.updated_date
               --
             END
           WHEN NOT isnull(pnModifiedLT) AND isnull(pnModifiedGTE) THEN kb.updated_date
           --
         END) DESC,
        (CASE
           --
           WHEN isnull(pnMinId) AND INSTR(vSort, "+") THEN
             --
             CASE vFieldSort 
               --
               WHEN 'order_number' THEN kb.order_number             
               WHEN 'updated_date' THEN kb.updated_date
               --
              END
           WHEN NOT isnull(pnMinId) THEN kb.id
           WHEN NOT isnull(pnModifiedGTE) THEN kb.updated_date
           --
         END) ASC
         --
   LIMIT pnPageSize
  OFFSET nOFFSET;
--
END