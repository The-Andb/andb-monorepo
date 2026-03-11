CREATE PROCEDURE `u2024_getCollectionTitleByUser`(pvCollectionIds       TEXT
                                                               ,pnUserId          BIGINT(20)
                                                               ,pvEmail  VARCHAR(100))
BEGIN
  --
  SELECT co.name title, co.id, co.is_trashed, co.`type`
    FROM collection co
    WHERE co.user_id = pnUserId
      AND find_in_set(co.id, pvCollectionIds)
    UNION
    SELECT co.name title, co.id, co.is_trashed, co.`type`
    FROM collection co
    JOIN user usr ON (co.user_id = usr.id)
    JOIN collection_shared_member csm ON (csm.collection_id = co.id AND csm.shared_status = 1)
    WHERE find_in_set(co.id, pvCollectionIds)
     AND csm.member_user_id = pnUserId
     AND co.type = 3
   ;
  --
END