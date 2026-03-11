CREATE PROCEDURE `k2024_listOfKanbanV2`(pvIds         TEXT
                                                        ,pvCollectionIds TEXT
                                                        ,pvCollectionId  BIGINT(20)
                                                        ,pnUserId        BIGINT(20)
                                                        ,pvUsername      VARCHAR(100)
                                                        ,pbIsArchive     TINYINT(1)
                                                        ,pnModifiedGTE   DOUBLE(14,4)
                                                        ,pnModifiedLT    DOUBLE(14,4)
                                                        ,pnMinId         BIGINT(20)
                                                        ,pnPageSize      INTEGER(11)
                                                        ,pnPageNo        INTEGER(11)
                                                        )
BEGIN
  --
  DECLARE nPageNo         INT(11) DEFAULT ifnull(pnPageNo, 0);
  DECLARE nOFFSET         INT(11) DEFAULT 0;
  --
  SET nOFFSET = IF(nPageNo > 0, (nPageNo - 1) * pnPageSize, 0);
  --
  SELECT kk.id, kk.collection_id, kk.name, kk.color
        ,kk.order_number, COALESCE(ki.archive_status, kk.archive_status, 0) archive_status, kk.order_update_time, kk.show_done_todo
        ,kk.add_new_obj_type, kk.sort_by_type, COALESCE(ki.archived_time, kk.archived_time, 0) archived_time, kk.kanban_type, kk.is_trashed
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
           WHERE IF(IFNULL(pvCollectionIds, 'NA') <> 'NA', FIND_IN_SET(co.id, pvCollectionIds), 1)
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
           WHERE IF(IFNULL(pvCollectionIds, 'NA') <> 'NA', FIND_IN_SET(co.id, pvCollectionIds), 1)
             AND co.is_trashed = 0
             AND csm.member_user_id = pnUserId
             AND co.type = 3 -- share only
            ) permistion ON (permistion.collection_id = kk.collection_id
            AND (kk.user_id = permistion.owner_user_id OR kk.user_id = permistion.member_user_id))
      
   WHERE IF(IFNULL(pvIds, 'NA') <> 'NA', FIND_IN_SET(kk.id, pvIds), 1)
     AND co.id = IFNULL(pvCollectionId, co.id)
     AND IF(IFNULL(pvCollectionIds, 'NA') <> 'NA', FIND_IN_SET(co.id, pvCollectionIds), 1)
     AND (kk.kanban_type    = 3 OR (kk.kanban_type IN (0, 1) AND kk.user_id = pnUserId))
     AND (kk.updated_date    < IF(IFNULL(pnModifiedLT, 0) > 0, pnModifiedLT, unix_timestamp() + 1)
            OR ki.updated_date    < IF(IFNULL(pnModifiedLT, 0) > 0, pnModifiedLT, unix_timestamp() + 1)
         )
     AND (kk.updated_date    >= IF(IFNULL(pnModifiedGTE, 0) > 0, pnModifiedGTE, 0)
           OR  ki.updated_date    >= IF(IFNULL(pnModifiedGTE, 0) > 0, pnModifiedGTE, 0)
         )
     AND kk.id > IF(IFNULL(pnMinId, 0) > 0, pnMinId, 0)
   GROUP BY kk.id
   ORDER BY 
         --
         (CASE          
            WHEN NOT isnull(pnModifiedLT) AND isnull(pnModifiedGTE) THEN kk.updated_date
             --  ELSE kk.id
           END) DESC,
        (CASE WHEN NOT isnull(pnModifiedGTE) THEN kk.updated_date
              WHEN ifnull(pnMinId, 0) > 0 THEN kk.id
          END) ASC
         --
   LIMIT pnPageSize
  OFFSET nOFFSET;
--
END