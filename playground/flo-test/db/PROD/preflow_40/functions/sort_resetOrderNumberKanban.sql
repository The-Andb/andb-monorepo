CREATE FUNCTION `sort_resetOrderNumberKanban`(nUSERID  BIGINT(20)) RETURNS DOUBLE(13,3)
BEGIN
  DECLARE no_more_rows boolean;
  DECLARE nId           BIGINT(20);
  DECLARE nCount        INT;
  DECLARE dUpdatedDate  DOUBLE(13,3) DEFAULT UNIX_TIMESTAMP();
  DECLARE nTotal        BIGINT;
  DECLARE nStep         DECIMAL(20,10);
  DECLARE kanban_cursor CURSOR FOR 
    SELECT k.id 
      FROM kanban k
     WHERE k.user_id = nUSERID
     ORDER BY k.order_number ASC;
  --
  DECLARE CONTINUE handler FOR NOT found SET no_more_rows = TRUE;
  --
  SELECT count(*)
    INTO nTotal
    FROM kanban k
   WHERE k.user_id = nUSERID;
   --
   SET nCount = ROUND(nTotal / -2);
   --
   SET nStep = s2025_calcStepResetSort(nTotal, NULL);
   --
   OPEN kanban_cursor;
   kanban_loop: LOOP
     --
     FETCH kanban_cursor INTO nId;
     -- stop LOOP WHEN no_more_rows
     IF (no_more_rows) THEN
       --
       CLOSE kanban_cursor;
       LEAVE kanban_loop;
       --
     END IF; 
     --
     UPDATE kanban k
        SET k.order_number = nCount * nStep + lpad(rand(), 13, 0)
           ,k.order_update_time = (@nReturn := dUpdatedDate + nCount * 1e-3)
           ,k.updated_date = @nReturn
      WHERE k.id = nId
        AND k.user_id = nUSERID;
  --
  SET nCount = nCount + 1;
  --
  END LOOP kanban_loop;
  --
  RETURN nCount;
  --
END