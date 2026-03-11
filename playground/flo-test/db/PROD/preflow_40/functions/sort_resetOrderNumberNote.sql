CREATE FUNCTION `sort_resetOrderNumberNote`(nUSERID BIGINT(20)) RETURNS DOUBLE(13,3)
BEGIN
  DECLARE no_more_rows boolean;
  DECLARE nId           BIGINT(20);
  DECLARE nCount        INT DEFAULT 0;
  DECLARE dUpdatedDate  DOUBLE(13,3) DEFAULT UNIX_TIMESTAMP();
  DECLARE nTotal        BIGINT;
  DECLARE nStep         DECIMAL(20,10);
  DECLARE note_cursor CURSOR FOR
    SELECT so.id 
      FROM sort_object so
     WHERE so.user_id = nUSERID
       AND so.object_type = 'VJOURNAL'
     ORDER BY so.order_number ASC;
  --
  DECLARE CONTINUE handler FOR NOT found SET no_more_rows = TRUE;
  --
  SELECT count(*)
    INTO nTotal
    FROM cloud c
   WHERE c.user_id = nUSERID;
   --
   SET nCount = ROUND(nTotal / -2);
   --
   SET nStep = s2025_calcStepResetSort(nTotal, NULL);
   --
   OPEN note_cursor;
   note_loop: LOOP
     --
     FETCH note_cursor INTO nId;
     -- stop LOOP WHEN no_more_rows
     IF (no_more_rows) THEN
       --
       CLOSE note_cursor;
       LEAVE note_loop;
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
  END LOOP note_loop;
  --
  RETURN nCount;
  --
END