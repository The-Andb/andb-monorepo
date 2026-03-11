CREATE PROCEDURE `u2024_getUrlTitleByUser`(pvObjectUid       VARBINARY(1000)
                                                   ,pnCollectionId    BIGINT(20)
                                                   ,pnUserId          BIGINT(20)
                                                   ,pvEmail  VARCHAR(100))
u2024_getUrlTitleByUser: BEGIN
    --
   IF ifnull(pnCollectionId, 0) > 0 THEN
     --
     SELECT u.title, u.uid, lco.is_trashed
       FROM url u
       JOIN linked_collection_object lco ON (u.uid = lco.object_uid)
       JOIN collection co  ON (lco.collection_id = co.id)
       JOIN user usr ON (co.user_id = usr.id)
       JOIN collection_shared_member csm ON (csm.collection_id = co.id AND csm.shared_status = 1)
      WHERE co.is_trashed = 0
        AND (pnCollectionId IS NULL OR csm.collection_id  = pnCollectionId)
        AND find_in_set(lco.object_uid, pvObjectUid)
        AND lco.object_type = 'URL'
        AND (co.user_id = pnUserId OR (
             csm.member_user_id = pnUserId
             AND csm.shared_status = 1
        ))
        AND co.type = 3
      GROUP BY lco.id
      ORDER BY lco.id DESC;
     --   
     LEAVE u2024_getUrlTitleByUser;
     --
   END IF;
   --
   SELECT u.title, u.uid, ifnull(tc.id, 0) > 0 AS is_trashed
     FROM url u
 LEFT JOIN trash_collection tc ON (u.user_id = tc.user_id AND u.uid = tc.object_uid AND tc.object_type = 'URL' AND tc.user_id = pnUserId)
    WHERE u.user_id = pnUserId
      AND find_in_set(u.uid, pvObjectUid)
 ORDER BY u.id DESC
  ;
  --
END