CREATE FUNCTION `sort_resetOrderNumberCloud`(nUSERID BIGINT(20)) RETURNS DOUBLE(13,3)
BEGIN
  DECLARE no_more_rows boolean;
  DECLARE nId           BIGINT(20);
  DECLARE nCount        INT;
  DECLARE dUpdatedDate  DOUBLE(13,3) DEFAULT UNIX_TIMESTAMP();
  DECLARE nTotal        BIGINT;
  DECLARE nStep         DECIMAL(20,10);
  DECLARE cloud_cursor CURSOR FOR 
    SELECT c.id 
      FROM cloud c
     WHERE c.user_id = nUSERID
     ORDER BY c.order_number ASC;
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
   OPEN cloud_cursor;
   cloud_loop: LOOP
     --
     FETCH cloud_cursor INTO nId;
     -- stop LOOP WHEN no_more_rows
     IF (no_more_rows) THEN
       --
       CLOSE cloud_cursor;
       LEAVE cloud_loop;
       --
     END IF; 
     --
     UPDATE cloud c
       SET c.order_number = nCount * nStep + lpad(rand(), 13, 0)
          ,c.order_update_time = (@nReturn := dUpdatedDate + nCount * 1e-3)
          ,c.updated_date = @nReturn
     WHERE c.id = nId
       AND c.user_id = nUSERID;
  --
  SET nCount = nCount + 1;
  --
  END LOOP cloud_loop;
  --
  RETURN nCount;
  --
END