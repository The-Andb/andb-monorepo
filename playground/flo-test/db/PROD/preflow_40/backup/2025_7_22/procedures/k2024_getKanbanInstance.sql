CREATE PROCEDURE `k2024_getKanbanInstance`(pnId      BIGINT(20)
                                                             ,pnUserId  BIGINT(20))
BEGIN
  --
  SELECT kb.id, kb.collection_id, kb.`name`, kb.created_date, kb.color
        ,kb.order_number, kb.archive_status, kb.order_update_time, kb.show_done_todo
        ,kb.add_new_obj_type, ifnull(ki.sort_by_type, 0) sort_by_type, kb.archived_time
        ,kb.user_id, kb.kanban_type, kb.is_trashed
        ,ifnull(ki.archive_status, 0) archive_status, ifnull(ki.archived_time, 0) archived_time
        ,greatest(ifnull(ki.updated_date, 0), kb.updated_date) updated_date
       FROM kanban kb
 INNER JOIN collection co ON (co.id = kb.collection_id)
  LEFT JOIN collection_shared_member csm ON (co.id = csm.collection_id)
  LEFT JOIN kanban_instance ki ON (kb.id = ki.kanban_id AND ki.user_id = pnUserId)
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
        AND kb.id = pnId
        AND co.is_trashed = 0
        AND kb.is_trashed = 0
      LIMIT 1;
 --
END