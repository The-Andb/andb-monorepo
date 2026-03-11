CREATE PROCEDURE `c2025_cleanEmail4Contacts`(
 IN pjEmails JSON
,OUT pvCleaned VARCHAR(2000))
BEGIN
  IF IFNULL(pjEmails, '') <> '' THEN
    --
    SELECT GROUP_CONCAT(DISTINCT LOWER(JSON_UNQUOTE(j.value)) SEPARATOR ',')
      INTO pvCleaned
      FROM JSON_TABLE(
      IF(JSON_TYPE(pjEmails) = 'ARRAY'
          ,pjEmails
          ,JSON_ARRAY(pjEmails)
          )
      ,'$[*]'
      COLUMNS (
        value VARCHAR(255) PATH '$.value',
        types JSON PATH '$.meta.type'
      )
    ) AS j
    ;
    --
  ELSE
    --
    SET pvCleaned = NULL;
    --
  END IF;
END