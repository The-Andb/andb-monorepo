CREATE PROCEDURE `u2024_getContactTitleByUser`(pvObjectUid       VARBINARY(1000)
                                                               ,pnUserId          BIGINT(20)
                                                               ,pvEmail  VARCHAR(100))
BEGIN
  --
  SELECT ct.title, ct.first_name, ct.last_name, ct.uid, ifnull(tc.id, 0) > 0 AS is_trashed
    FROM cards ca
    JOIN  card_contact ct ON (ca.uri = concat(ct.uid, '.vcf'))
    JOIN addressbooks ab ON (ab.id = ca.addressbookid AND ab.id = ct.addressbookid)
    JOIN principals pp ON (pp.uri = ab.principaluri)
    LEFT JOIN trash_collection tc ON (ct.uid = tc.object_uid AND tc.object_type = 'VCARD' AND tc.user_id = pnUserId)
   WHERE pp.uri = concat('principals/', pvEmail)
     AND find_in_set(ct.uid, pvObjectUid)
     ORDER BY ca.id DESC
   ;
  --
END