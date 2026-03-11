CREATE FUNCTION `OTE_patchCardContactEmailText`() RETURNS INT
BEGIN
  DECLARE no_more_rows BOOLEAN;
  DECLARE pjEmails JSON;
  DECLARE nId BIGINT;
  DECLARE vCleaned VARCHAR(2000);
  DECLARE nCount INT DEFAULT 0;
  
  --
  DECLARE usr_cursor CURSOR FOR
    SELECT cc.id
         , cc.email_address
      FROM card_contact cc
     WHERE cc.email_text IS NULL
       AND cc.email_address IS NOT NULL;
  
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET no_more_rows = TRUE;
  
  OPEN usr_cursor;
  
  usr_loop: LOOP
    FETCH usr_cursor INTO nId, pjEmails;
    
    IF no_more_rows THEN
      LEAVE usr_loop;
    END IF;
    
    SELECT GROUP_CONCAT(DISTINCT LOWER(JSON_UNQUOTE(j.value)) SEPARATOR ',')
      INTO vCleaned
      FROM JSON_TABLE(
        IF(JSON_TYPE(pjEmails) = 'ARRAY'
          ,pjEmails
          ,JSON_ARRAY(pjEmails)
          ),'$[*]'
        COLUMNS (
          value VARCHAR(255) PATH '$.value',
          types JSON PATH '$.meta.type'
        )
      ) AS j;
      
    UPDATE card_contact
       SET email_text = vCleaned
     WHERE id = nId;
    
    SET nCount = nCount + 1;
  END LOOP;
  
  CLOSE usr_cursor;
  RETURN nCount;
END