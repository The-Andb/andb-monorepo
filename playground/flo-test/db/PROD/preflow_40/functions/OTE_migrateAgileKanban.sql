CREATE FUNCTION `OTE_migrateAgileKanban`(pnUserId BIGINT(20)) RETURNS INT
BEGIN
   DECLARE no_more_rows      boolean;
   DECLARE collectionId     BIGINT(20);
  -- DECLARE userId           BIGINT(20);
   DECLARE orderNumber      DECIMAL(20,10);
   DECLARE updatedDate      DOUBLE(14,4);
   DECLARE nCount           INT(11) DEFAULT 0;
   DECLARE nCountAgile      INT(11) DEFAULT -1;
   DECLARE nCountAvg        INT(11) DEFAULT 0;
  
   DECLARE kanban_cursor CURSOR FOR
   # Start of: main script
  
   SELECT DISTINCT k.collection_id
    FROM kanban k
    JOIN collection c ON (c.id = k.collection_id AND c.`type` = 3 AND c.is_trashed = 0)
   WHERE k.user_id = pnUserId 
     AND k.kanban_type = 1;

   # END of: main script
   DECLARE CONTINUE handler FOR NOT FOUND SET no_more_rows = TRUE;

   -- LOOP
   OPEN kanban_cursor;
   kanban_loop: LOOP
   -- 
   FETCH kanban_cursor INTO collectionId;
   
   
    SELECT count(*), AVG(sub.order_number), ifnull(AVG(sub.updated_date), 0)
    INTO nCountAvg, orderNumber, updatedDate
  FROM (
      SELECT k.order_number, k.updated_date
        FROM kanban k
       WHERE k.collection_id = collectionId
         AND k.user_id = pnUserId
         AND k.order_number >= (
              SELECT order_number
                FROM kanban
               WHERE collection_id = collectionId
                 AND user_id = pnUserId
                 AND name = 'Notifications'
               LIMIT 1
          )
      ORDER BY k.order_number ASC
      LIMIT 2
  ) sub;

   -- 
   IF (no_more_rows) THEN
       CLOSE kanban_cursor;
       LEAVE kanban_loop;
   END IF;
   -- 
   -- CHECK exist Agile kanban
   SELECT count(*)
      INTO nCountAgile
     FROM kanban k
    WHERE k.name = 'Agile' 
      AND k.user_id = pnUserId 
      AND k.collection_id = collectionId;
   
   -- Noti last position
   IF nCountAvg = 1 THEN
       SET orderNumber = orderNumber + 0.0001;
       SET updatedDate = updatedDate + 0.0001;
   END IF;
   
   -- 
   IF (nCountAgile = 0) THEN
        -- INSERT new agile kanban card
     INSERT INTO kanban
     (user_id, collection_id, name, color, order_number, archive_status, order_kbitem, order_update_time
         ,show_done_todo, add_new_obj_type, sort_by_type, archived_time, kanban_type, is_trashed, created_date, updated_date, kanban_status_value) 
     VALUES(pnUserId, collectionId, 'Agile', '#f2f4f5', orderNumber, 0, NULL, updatedDate, 0, 0, 0, 0.000, 1, 0, updatedDate, updatedDate, 0)
       ON DUPLICATE KEY UPDATE updated_date = VALUES(updated_date) + 0.0001
                              ,created_date = VALUES(updated_date) + 0.0001;
     -- 
     SET nCount = nCount + 1;
     -- 
   END IF;
   -- 
   END LOOP kanban_loop;
     
RETURN nCount;
END