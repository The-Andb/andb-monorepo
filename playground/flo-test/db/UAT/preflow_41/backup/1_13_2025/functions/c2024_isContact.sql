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
 SELECT ifnull(cc.id, 0) > 0
   INTO nReturn
   FROM principals pp
   JOIN addressbooks ab ON (pp.uri = ab.principaluri)
   JOIN card_contact cc ON (cc.addressbookid = ab.id)
  WHERE pp.uri = concat('principals/', pvUsername)
    AND JSON_EXTRACT(cc.email_address,'$[*].value') RLIKE pvEmailContact
    AND (ifnull(pbRequiredVIP, 0) = 0 
          OR (pbRequiredVIP = 1 AND cc.vip = 1)
        )
   ;
  --
  RETURN nReturn;
  --
END