CREATE FUNCTION `sort_resetOrderNumberUrl`(nUSERID BIGINT(20)) RETURNS DOUBLE(13,3)
BEGIN
  DECLARE no_more_rows boolean;
  DECLARE nId           BIGINT(20);
  DECLARE nCount        INT DEFAULT 0;
  DECLARE dUpdatedDate  DOUBLE(13,3) DEFAULT UNIX_TIMESTAMP();
  DECLARE nTotal        BIGINT;
  DECLARE nStep         DECIMAL(20,10);
  DECLARE url_cursor CURSOR FOR 
    SELECT u.id 
      FROM url u
     WHERE u.user_id = nUSERID
     ORDER BY u.order_number ASC;
  --
  DECLARE CONTINUE handler FOR NOT found SET no_more_rows = TRUE;
  --
  SELECT count(*)
    INTO nTotal
    FROM url u
   WHERE u.user_id = nUSERID;
   --
   SET nCount = ROUND(nTotal / -2);
   --
   SET nStep = s2025_calcStepResetSort(nTotal, NULL);
   --
   OPEN url_cursor;
   url_loop: LOOP
     --
     FETCH url_cursor INTO nId;
     -- stop LOOP WHEN no_more_rows
     IF (no_more_rows) THEN
       --
       CLOSE url_cursor;
       LEAVE url_loop;
       --
     END IF; 
     --
     UPDATE url u
        SET u.order_number = nCount * nStep + lpad(rand(), 13, 0)
           ,u.order_update_time = (@nReturn := dUpdatedDate + nCount * 1e-3)
           ,u.updated_date = @nReturn
      WHERE u.id = nId
        AND u.user_id = nUSERID;
  --
  SET nCount = nCount + 1;
  --
  END LOOP url_loop;
  --
  RETURN nCount;
  --
END