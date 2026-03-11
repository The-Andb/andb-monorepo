CREATE FUNCTION `c2024_isContact`(pvUsername       VARCHAR(100) -- owner addressbook
                                                    ,pvEmailContact   VARCHAR(100) -- contact email
                                                    ,pbRequiredVIP    TINYINT(1)) RETURNS INT
BEGIN
  --
  DECLARE nReturn TINYINT(1) DEFAULT 0;
  --
  IF ifnull(pvUsername, '') = '' OR ifnull(pvEmailContact, '') = '' THEN
    RETURN 0;
  END IF;
  --
 SELECT ifnull(max(cc.id), 0) > 0
   INTO nReturn
   FROM principals pp
   JOIN addressbooks ab ON (pp.uri = ab.principaluri)
   JOIN card_contact cc ON (cc.addressbookid = ab.id)
 LEFT JOIN trash_collection tc ON (tc.object_uid = cc.uid AND tc.object_type = 'VCARD')
  WHERE pp.uri = concat('principals/', pvUsername)
    AND JSON_EXTRACT(cc.email_address,'$[*].value') RLIKE pvEmailContact
    AND (ifnull(pbRequiredVIP, 0) = 0 
          OR (pbRequiredVIP = 1 AND cc.vip = 1)
        )
    AND tc.id IS NULL
   ;
  --
  RETURN nReturn;
  --
END