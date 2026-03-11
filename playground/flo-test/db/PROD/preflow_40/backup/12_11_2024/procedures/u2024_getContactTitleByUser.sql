CREATE PROCEDURE `u2024_getContactTitleByUser`(pvObjectUid       VARBINARY(1000)
                                                               ,pnUserId          BIGINT(20)
                                                               ,pvEmail  VARCHAR(100))
BEGIN
  --
  SELECT ct.title, ct.first_name, ct.last_name, ct.uid
    FROM cards ca
    JOIN  card_contact ct ON (ca.uri = concat(ct.uid, '.vcf'))
    JOIN addressbooks ab ON (ab.id = ca.addressbookid AND ab.id = ct.addressbookid)
    JOIN principals pp ON (pp.uri = ab.principaluri)
   WHERE pp.uri = concat('principals/', pvEmail)
     AND find_in_set(ct.uid, pvObjectUid)
   ;
  --
END