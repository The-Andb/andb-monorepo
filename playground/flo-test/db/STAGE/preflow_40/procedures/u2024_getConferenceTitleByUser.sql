CREATE PROCEDURE `u2024_getConferenceTitleByUser`(pvObjectUid       VARBINARY(1000)
                                                               ,pnUserId          BIGINT(20)
                                                               ,pvEmail  VARCHAR(100))
BEGIN
  --
 SELECT IF(ifnull(cc.collection_id,0) > 0
          ,cc.title -- always USE share title for shared channel
          ,COALESCE(NULLIF(cm.title, ''), cc.title, '')) title, cc.uid
     FROM conference_channel cc
     JOIN conference_member cm ON (cm.channel_id = cc.id)
    WHERE cm.user_id = pnUserId
      AND cm.revoke_time = 0
      AND cc.is_trashed = 0
      AND find_in_set(cc.uid, pvObjectUid)
   ;
  --
END