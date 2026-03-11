CREATE FUNCTION `n2024_considerMentionInNotificationForChatV2`(pnNotiID             BIGINT(20)
                                                                               ,pnUserId             BIGINT(20)
                                                                               ,pvObjectUid           VARBINARY(1000)
                                                                               ,pvObjectType          VARBINARY(50)
                                                                               ,pvMentionList         TEXT -- anb@dm.xc,anb@dm.xc
                                                                               ,pnActionTime         DOUBLE(13,3)
                                                                               ,pnUpdatedDate        DOUBLE(13,3)
                                                                               ) RETURNS BIGINT
BEGIN
  --
  DECLARE nCountEmail INTEGER;
  DECLARE nCursor INT DEFAULT 1;
  DECLARE nUserId INT(11);
  DECLARE nReturn INT(11);
  DECLARE nNotiID INT(11) DEFAULT ifnull(pnNotiID, 0);
  DECLARE vEmail VARCHAR(255);

  -- email count
  SET nCountEmail = LENGTH(pvMentionList) - LENGTH(REPLACE(pvMentionList, ',', '')) + 1;
  --
  IF nNotiID = 0 THEN
     --
     SELECT ifnull(max(cn.id), 0)
       INTO nNotiID
       FROM collection_notification cn
       WHERE cn.object_type = pvObjectType
         AND cn.object_uid = pvObjectUid
         AND cn.user_id = pnUserId;
     --
   END IF;
   -- nothing TO UPDATE
   IF nNotiID = 0 THEN
     --
     RETURN 0;
     --
   END IF;
  -- LOOP throw count
  simple_loop: LOOP
    --
    SET vEmail = REPLACE(SUBSTRING(SUBSTRING_INDEX(pvMentionList, ',', nCursor),
                       LENGTH(SUBSTRING_INDEX(pvMentionList, ',', nCursor -1)) + 1), ',', '');
                       
    -- GET user id
    SELECT u.id
      INTO nUserId
      FROM `user` u
     WHERE u.email = vEmail;
    --
    SET nReturn = n2023_createUserNotification(nNotiID, 0, 1, pnActionTime, pnUpdatedDate, pnUpdatedDate, NULL, nUserId, NULL);
    # main UPDATE
  --
  IF nCursor = nCountEmail THEN
    LEAVE simple_loop;
  END IF;
  --
  SET nCursor = nCursor + 1;
  END LOOP simple_loop;
  --
  RETURN nNotiID;
  --
END