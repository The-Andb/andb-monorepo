CREATE PROCEDURE `k2024_listOfKanbanCardV3`(pvIds         TEXT
                                                        ,pnCollectionId  BIGINT(20)
                                                        ,pnUserId        BIGINT(20)
                                                        ,pvUsername      VARCHAR(100)
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
  SELECT kc.id, kc.object_type, kc.item_card_order, kc.kanban_id, kc.account_id, kc.order_number
        ,kc.order_update_time, kc.object_href, kc.is_trashed, kc.recent_date, kc.object_uid
        ,kc.created_date, kc.updated_date, kc.user_id
        ,permistion.member_calendar_uri, permistion.member_email, permistion.member_user_id
        ,permistion.owner_user_id, permistion.owner_calendar_uri, permistion.owner_username, permistion.owner_user_id
    FROM kanban_card kc
     JOIN kanban kb ON (kc.kanban_id = kb.id)
LEFT JOIN kanban_instance ki ON (ki.kanban_id = kb.id AND ki.user_id = pnUserId)
     JOIN collection co ON (kb.collection_id = co.id)
     JOIN (
         -- owner existed collection_id
          SELECT co.id collection_id, co.calendar_uri owner_calendar_uri, co.user_id owner_user_id
                ,'' member_calendar_uri, '' member_email
                ,0 member_user_id
                ,usr.username owner_username
            FROM collection co
            JOIN user usr ON (co.user_id = usr.id)
           WHERE IF(IFNULL(pnCollectionId, 0) = 0, 1, co.id = pnCollectionId)
            -- AND (co.`type` = 3 OR (pnCollectionId > 0 OR pvObjectUid <> '')) -- owner GET BY uid? dont need TO share
             AND co.user_id = pnUserId
          UNION
          -- member existed collection_id
          SELECT co.id collection_id, co.calendar_uri owner_calendar_uri, co.user_id owner_user_id
                ,csm.calendar_uri member_calendar_uri, csm.shared_email member_email
                ,csm.member_user_id
                ,usr.username owner_username
            FROM collection co
            JOIN user usr ON (co.user_id = usr.id)
            JOIN collection_shared_member csm ON (csm.collection_id = co.id AND csm.shared_status = 1)
           WHERE IF(IFNULL(pnCollectionId, 0) = 0, 1, co.id = pnCollectionId)
             AND co.is_trashed = 0
             AND csm.member_user_id = pnUserId
             AND co.type = 3 -- share only
            ) permistion ON (permistion.collection_id = kb.collection_id
            AND (kb.user_id = permistion.owner_user_id OR kb.user_id = permistion.member_user_id))
   WHERE IF(IFNULL(pvIds, 'NA') <> 'NA', FIND_IN_SET(kc.id, pvIds), 1)
     AND IF(IFNULL(pnCollectionId, 0) = 0, 1, co.id = pnCollectionId)
     AND IF(ifnull(pnIncludeShared, 0) = 1, 1, kb.kanban_type <> 3)
     AND (kb.kanban_type    = 3 OR (kb.kanban_type IN (0, 1) AND kb.user_id = pnUserId))
     AND kc.updated_date    < IF(IFNULL(pnModifiedLT, 0) > 0, pnModifiedLT, unix_timestamp() + 1)
     AND kc.updated_date    >= IF(IFNULL(pnModifiedGTE, 0) > 0, pnModifiedGTE, 0)
     AND kc.id > IF(IFNULL(pnMinId, 0) > 0, pnMinId, 0)
   GROUP BY kc.id
   ORDER BY
        (CASE
           --
           WHEN isnull(pnMinId) AND INSTR(vSort, "-") THEN
             --
             CASE vFieldSort
               --
               WHEN 'order_number' THEN kc.order_number            
               WHEN 'updated_date' THEN kc.updated_date
               --
             END
           WHEN NOT isnull(pnModifiedLT) AND isnull(pnModifiedGTE) THEN kc.updated_date
           --
         END) DESC,
        (CASE
           --
           WHEN isnull(pnMinId) AND INSTR(vSort, "+") THEN
             --
             CASE vFieldSort 
               --
               WHEN 'order_number' THEN kc.order_number             
               WHEN 'updated_date' THEN kc.updated_date
               --
              END
           WHEN NOT isnull(pnMinId) THEN kc.id
           WHEN NOT isnull(pnModifiedGTE) THEN kc.updated_date
           --
         END) ASC
         --
   LIMIT pnPageSize
  OFFSET nOFFSET;
--
END