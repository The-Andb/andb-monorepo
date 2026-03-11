CREATE PROCEDURE `c2025_listOfVIP`(pvEmail VARCHAR(100))
BEGIN
  --
  SELECT jt.email
        FROM card_contact cc
        JOIN addressbooks ab ON cc.addressbookid = ab.id
        JOIN JSON_TABLE(
             CASE
               WHEN cc.email_text IS NULL OR cc.email_text = ''
               THEN '[]'
               ELSE CONCAT(
                  '["',
                  REPLACE(TRIM(cc.email_text), ',', '","'),
                  '"]'
                )
             END
             ,'$[*]' COLUMNS (email VARCHAR(255) PATH '$')
      ) jt
      WHERE ab.uri = pvEmail
        AND cc.vip = 1;
  --
END