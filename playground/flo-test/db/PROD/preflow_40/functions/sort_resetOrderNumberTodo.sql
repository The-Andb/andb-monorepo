CREATE FUNCTION `sort_resetOrderNumberTodo`(nUSERID BIGINT(20)) RETURNS DOUBLE(13,3)
BEGIN
  DECLARE no_more_rows boolean;
  DECLARE nId           BIGINT(20);
  DECLARE nCount        INT DEFAULT 0;
  DECLARE dUpdatedDate  DOUBLE(13,3) DEFAULT UNIX_TIMESTAMP();
  DECLARE nTotal        BIGINT;
  DECLARE nStep         DECIMAL(20,10);
  DECLARE todo_cursor CURSOR FOR 
    SELECT so.id 
      FROM sort_object so
     WHERE so.user_id = nUSERID
       AND so.object_type = 'VTODO'
     ORDER BY so.order_number ASC;
  --
  DECLARE CONTINUE handler FOR NOT found SET no_more_rows = TRUE;
  --
  SELECT count(*)
    INTO nTotal
    FROM sort_object so
   WHERE so.user_id = nUSERID
     AND so.object_type = 'VTODO';
   --
   SET nCount = ROUND(nTotal / -2);
   --
   SET nStep = s2025_calcStepResetSort(nTotal, NULL);
   --
   OPEN todo_cursor;
   todo_loop: LOOP
     --
     FETCH todo_cursor INTO nId;
     -- stop LOOP WHEN no_more_rows
     IF (no_more_rows) THEN
       --
       CLOSE todo_cursor;
       LEAVE todo_loop;
       --
     END IF; 
     --
     UPDATE sort_object so
        SET so.order_number = nCount * nStep + lpad(rand(), 13, 0)
           ,so.order_update_time = (@nReturn := dUpdatedDate + nCount * 1e-3)
           ,so.updated_date = @nReturn
      WHERE so.id = nId
        AND so.user_id = nUSERID;
  --
  SET nCount = nCount + 1;
  --
  END LOOP todo_loop;
  --
  RETURN nCount;
  --
END