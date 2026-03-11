CREATE PROCEDURE `c2025_cleanEmail4Mentions`(
 IN pjEmails JSON
,OUT pvCleaned VARCHAR(2000))
BEGIN
  IF ifnull(pjEmails,'') <> '' THEN 
    --
    SELECT GROUP_CONCAT(JSON_UNQUOTE(j.email))
      INTO pvCleaned
      FROM JSON_TABLE(
       pjEmails, '$.mentions[*]'
       COLUMNS (email VARCHAR(255) PATH '$.email')
      ) AS j;
    --
  ELSE
    --
    SET pvCleaned = NULL;
    --
  END IF;
END