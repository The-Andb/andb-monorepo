CREATE PROCEDURE `u2024_getCloudTitleByUser`(pvObjectUid       VARBINARY(1000)
                                                               ,pnUserId          BIGINT(20)
                                                               ,pvEmail  VARCHAR(100))
BEGIN
  --
  SELECT cl.real_filename title, cl.uid,  ifnull(tc.id, 0) > 0 AS is_trashed
    FROM cloud cl
LEFT JOIN trash_collection tc ON (cl.user_id = tc.user_id AND cl.uid = tc.object_uid AND tc.object_type = 'CSFILE' AND tc.user_id = pnUserId)
    WHERE cl.user_id = pnUserId
      AND find_in_set(cl.uid, pvObjectUid)
      ORDER BY cl.id DESC
   ;
  --
END