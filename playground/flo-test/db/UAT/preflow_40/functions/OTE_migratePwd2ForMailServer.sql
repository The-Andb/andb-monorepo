CREATE FUNCTION `OTE_migratePwd2ForMailServer`() RETURNS INT
BEGIN
    DECLARE no_more_rows        boolean;
    DECLARE nCount              INT DEFAULT 0;
    DECLARE nID           BIGINT(20);
    DECLARE vPassword2    VARCHAR(255);
   
    
    DECLARE usr_cursor CURSOR FOR
    # Start of: main script;
    SELECT u2.id, u1.password2
      FROM preflow_40.user u1 
      JOIN mail.user u2 ON (u1.username = u2.username)
     WHERE ifnull(u2.password2, '') = ''
     ;
    # END of: main script
   DECLARE CONTINUE handler FOR NOT found SET no_more_rows = TRUE;
   --
   OPEN usr_cursor;
   usr_loop: LOOP
     -- start LOOP usr_cursor
     FETCH usr_cursor
      INTO nID, vPassword2;
     -- stop LOOP WHEN no_more_rows
     IF (no_more_rows) THEN
       CLOSE usr_cursor;
       LEAVE usr_loop;
     END IF;
     # main UPDATE
     --
     UPDATE mail.user u
        SET u.password2 = vPassword2
      WHERE u.id = nID;
     --
     SET nCount = nCount + 1;
     # main UPDATE
     --
  END LOOP usr_loop;
  --
  RETURN nCount;
  --
END