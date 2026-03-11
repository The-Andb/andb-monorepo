CREATE PROCEDURE `u2024_getCloudTitleByUser`(pvObjectUid       VARBINARY(1000)
                                                               ,pnUserId          BIGINT(20)
                                                               ,pvEmail  VARCHAR(100))
BEGIN
  --
  SELECT cl.real_filename title, cl.uid
    FROM cloud cl
    WHERE cl.user_id = pnUserId
      AND find_in_set(cl.uid, pvObjectUid)
   ;
  --
END