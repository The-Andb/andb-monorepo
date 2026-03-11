CREATE FUNCTION `k2024_generateSystemKanbanV2`(pnUserId BIGINT(20)
                                                          ,pnCollectionId BIGINT(20)
                                                          ,pnUpdatedDate DOUBLE(13,3)
                                                          ) RETURNS INT
BEGIN
  --
  DECLARE nModifyDate      DOUBLE(13,3);
  DECLARE nIsOwner         TINYINT(1) DEFAULT 0;
  DECLARE nColType         TINYINT(1) DEFAULT 0;
  DECLARE nCountKanban     INT DEFAULT 0;
  DECLARE nReturn          BIGINT(20) DEFAULT 0;
  --
  IF ifnull(pnCollectionId, 0) = 0 OR ifnull(pnUserId, 0) = 0 THEN
    --
    RETURN 0;
    --
  END IF;
  --
  SELECT ifnull(pnUserId, 0) = ifnull(c.user_id, -1), ifnull(c.type, -1)
  INTO nIsOwner, nColType
  FROM collection c
  WHERE c.id = pnCollectionId;
  -- 
  SELECT count(*)
    INTO nCountKanban
    FROM kanban k
   WHERE k.collection_id = pnCollectionId
     AND k.user_id = pnUserId
     AND k.kanban_type = 1; -- system;
   -- skip FOR prevent DUPLICATE
   IF ifnull(nCountKanban, 0) > 0 THEN
     --
     RETURN -2;
     --
   END IF;
  --
  # END of: main script
  --
  SET nModifyDate = pnUpdatedDate;
  -- share only
  IF nColType = 3 THEN
    --
    IF nIsOwner = 1 THEN
      -- Members, **Notifications**, Status FOR Todo's, Recently Added, Email, Event, ToDo's, Contacts, Calls, Notes, Websites
      INSERT INTO kanban (user_id, collection_id, `name`, color, order_number, archive_status, order_kbitem, order_update_time, show_done_todo, add_new_obj_type, sort_by_type, archived_time, kanban_type, is_trashed, created_date, updated_date) 
      VALUES
        -- Members
        (pnUserId, pnCollectionId, 'Members',       '#666666',    0 + ROUND(RAND()/100, 3), 0, NULL,  pnUpdatedDate + 0.007, 0, 0, 0, 0.000, 1, 0,  pnUpdatedDate - 0.007,  pnUpdatedDate - 0.007),
        -- Notifications
        (pnUserId, pnCollectionId, 'Notifications', '#49BB89', 0.5 + ROUND(RAND()/100, 3), 0, NULL,  pnUpdatedDate + 0.008, 0, 0, 3, 0.000, 1, 0,  pnUpdatedDate - 0.008,  pnUpdatedDate - 0.008)
        ;
      --
     ELSE
       -- Members, *Notifications*, Status FOR ToDo's, Recently Added, Event, ToDo's, Calls, Notes, Websites
       INSERT INTO kanban 
         (user_id, collection_id,`name`,color, order_number, archive_status, order_kbitem, order_update_time, show_done_todo, add_new_obj_type, sort_by_type, archived_time, kanban_type, is_trashed, created_date, updated_date) 
       VALUES
         -- Notifications
         (pnUserId, pnCollectionId,  'Notifications', '#49BB89', -0.5 + ROUND(RAND()/100, 3), 0, NULL,  pnUpdatedDate + 0.001, 0, 0, 3, 0.000, 1, 0,  pnUpdatedDate - 0.001,  pnUpdatedDate - 0.001),
         -- Status FOR Todo's
         (pnUserId, pnCollectionId,  'Status FOR ToDo\'s', '#f2f4f5', 0 + ROUND(RAND()/100, 3), 0, NULL,  pnUpdatedDate + 0.002, 0, 0, 3, 0.000, 1, 0,  pnUpdatedDate - 0.002,  pnUpdatedDate - 0.002),
         -- Recently Added
         (pnUserId, pnCollectionId, 'Recently Added', '#007AFF',    1 + ROUND(RAND()/100, 3), 0, NULL,  pnUpdatedDate + 0.003, 0, 0, 3, 0.000, 1, 0,  pnUpdatedDate - 0.003,  pnUpdatedDate - 0.003),
         -- EventsΩ
         (pnUserId, pnCollectionId,         'Events', '#f94956',    2 + ROUND(RAND()/100, 3), 0, NULL,  pnUpdatedDate + 0.004, 0, 0, 3, 0.000, 1, 0,  pnUpdatedDate - 0.004,  pnUpdatedDate - 0.004),
         -- Calls
         (pnUserId, pnCollectionId,        'ToDo\'s', '#7CCD2D',    3 + ROUND(RAND()/100, 3), 0, NULL,  pnUpdatedDate + 0.005, 0, 0, 0, 0.000, 1, 0,  pnUpdatedDate - 0.005,  pnUpdatedDate - 0.005),
         -- ToDo
         (pnUserId, pnCollectionId,          'Calls', '#49BB89',    4 + ROUND(RAND()/100, 3), 0, NULL,  pnUpdatedDate + 0.006, 0, 0, 3, 0.000, 1, 0,  pnUpdatedDate - 0.006,  pnUpdatedDate - 0.006),
         -- Notes
         (pnUserId, pnCollectionId,          'Notes', '#FFA834',    5 + ROUND(RAND()/100, 3), 0, NULL,  pnUpdatedDate + 0.007, 0, 0, 3, 0.000, 1, 0,  pnUpdatedDate - 0.007,  pnUpdatedDate - 0.007),
         -- Websites
         (pnUserId, pnCollectionId,       'Websites', '#B658DE',    6 + ROUND(RAND()/100, 3), 0, NULL,  nModifyDate, 0, 0, 3, 0.000, 1, 0,  nModifyDate,  nModifyDate)
        ;
      --
      -- SET nReturn = m2023_insertAPILastModify('kanban', pnUserId, nModifyDate);
      --
      RETURN 2;
      --
    END IF;
    --
  END IF;
  --
  IF nIsOwner = 1 THEN
    -- Status FOR ToDo's, Recently Added, Email, Event, ToDo's, Contacts, Calls, Notes, Websites, Files
    INSERT INTO kanban 
      (user_id, collection_id, `name`, color, order_number, archive_status, order_kbitem, order_update_time, show_done_todo, add_new_obj_type, sort_by_type, archived_time, kanban_type, is_trashed, created_date, updated_date) 
    VALUES
      -- Status FOR Todo's
      (pnUserId, pnCollectionId, 'Status FOR ToDo\'s', '#f2f4f5', 1 + ROUND(RAND()/100, 3), 0, NULL,  pnUpdatedDate + 0.009, 0, 0, 3, 0.000, 1, 0,  pnUpdatedDate - 0.009,  pnUpdatedDate - 0.009),
      -- Recently Added
      (pnUserId, pnCollectionId, 'Recently Added', '#007AFF', 2 + ROUND(RAND()/100, 3), 0, NULL,  pnUpdatedDate + 0.010, 0, 0, 3, 0.000, 1, 0,  pnUpdatedDate - 0.010,  pnUpdatedDate - 0.010),
      -- Email
      (pnUserId, pnCollectionId,          'Email', '#0074b3', 3 + ROUND(RAND()/100, 3), 0, NULL,  pnUpdatedDate + 0.011, 0, 0, 3, 0.000, 1, 0,  pnUpdatedDate - 0.011,  pnUpdatedDate - 0.011),
      -- Events
      (pnUserId, pnCollectionId,         'Events', '#f94956', 4 + ROUND(RAND()/100, 3), 0, NULL,  pnUpdatedDate + 0.012, 0, 0, 3, 0.000, 1, 0,  pnUpdatedDate - 0.012,  pnUpdatedDate - 0.012),
      -- ToDo
     (pnUserId, pnCollectionId,        'ToDo\'s', '#7CCD2D', 5 + ROUND(RAND()/100, 3), 0, NULL,  pnUpdatedDate + 0.013, 0, 0, 0, 0.000, 1, 0,  pnUpdatedDate - 0.013,  pnUpdatedDate - 0.013),
     -- Contacts
     (pnUserId, pnCollectionId,       'Contacts', '#a0867d', 6 + ROUND(RAND()/100, 3), 0, NULL,  pnUpdatedDate + 0.014, 0, 0, 1, 0.000, 1, 0,  pnUpdatedDate - 0.014,  pnUpdatedDate - 0.014),
     -- Calls
     (pnUserId, pnCollectionId,          'Calls', '#49BB89', 7 + ROUND(RAND()/100, 3), 0, NULL,  pnUpdatedDate + 0.015, 0, 0, 3, 0.000, 1, 0,  pnUpdatedDate - 0.015,  pnUpdatedDate - 0.015),
     -- Notes
     (pnUserId, pnCollectionId,          'Notes', '#FFA834', 8 + ROUND(RAND()/100, 3), 0, NULL,  pnUpdatedDate + 0.016, 0, 0, 3, 0.000, 1, 0,  pnUpdatedDate - 0.016,  pnUpdatedDate - 0.016),
     -- Websites
     (pnUserId, pnCollectionId,       'Websites', '#B658DE', 9 + ROUND(RAND()/100, 3), 0, NULL,  pnUpdatedDate + 0.017, 0, 0, 3, 0.000, 1, 0,  pnUpdatedDate - 0.017,  pnUpdatedDate - 0.017),
     -- Files
     (pnUserId, pnCollectionId,          'Files', '#969696', 10 + ROUND(RAND()/100, 3), 0, NULL,  nModifyDate, 0, 0, 0, 0.000, 1, 0,  nModifyDate,  nModifyDate)
     ;
    RETURN 1;
    --
  END IF;
  --
  RETURN -1;
  --
END