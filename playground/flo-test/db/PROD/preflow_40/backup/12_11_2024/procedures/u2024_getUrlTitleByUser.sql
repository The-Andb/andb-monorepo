CREATE PROCEDURE `u2024_getUrlTitleByUser`(pvObjectUid       VARBINARY(1000)
                                                   ,pnCollectionId    BIGINT(20)
                                                   ,pnUserId          BIGINT(20)
                                                   ,pvEmail  VARCHAR(100))
u2024_getUrlTitleByUser: BEGIN
    --
   IF ifnull(pnCollectionId, 0) > 0 THEN
     --
     SELECT u.title, u.uid
       FROM url u
       JOIN linked_collection_object lco ON (u.uid = lco.object_uid)
       JOIN collection co  ON (lco.collection_id = co.id)
       JOIN user usr ON (co.user_id = usr.id)
       JOIN collection_shared_member csm ON (csm.collection_id = co.id AND csm.shared_status = 1)
      WHERE co.is_trashed = 0
        AND (pnCollectionId IS NULL OR csm.collection_id  = pnCollectionId)
        AND find_in_set(lco.object_uid, pvObjectUid)
        AND lco.is_trashed = 0
        AND csm.member_user_id = pnUserId
        AND lco.object_type = 'URL'
        AND csm.shared_status = 1
        AND co.type = 3;
     LEAVE u2024_getUrlTitleByUser;
     --
   END IF;
   --
   SELECT u.title, u.uid
     FROM url u
    WHERE u.user_id = pnUserId
      AND find_in_set(u.uid, pvObjectUid);
  --
END