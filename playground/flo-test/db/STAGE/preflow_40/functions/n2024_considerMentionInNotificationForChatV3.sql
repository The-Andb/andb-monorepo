CREATE FUNCTION `n2024_considerMentionInNotificationForChatV3`(pvContent          VARCHAR(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
                                                                               ,pnNotiID             BIGINT(20)
                                                                               ,pnUserId             BIGINT(20)
                                                                               ,pvObjectUid          VARBINARY(1000)
                                                                               ,pvObjectType         VARBINARY(50)
                                                                               ,pvMentionList        TEXT -- anb@dm.xc,anb@dm.xc
                                                                               ,pnActionTime         DOUBLE(13,3)
                                                                               ,pnUpdatedDate        DOUBLE(13,3)
                                                                               ) RETURNS BIGINT
BEGIN
  -- only CALL FROM edit chat
  DECLARE nCountEmail   INTEGER;
  DECLARE nCursor       INT DEFAULT 1;
  DECLARE nUserId       INT(11);
  DECLARE nReturn       INT(11);
  DECLARE nNotiID       INT(11) DEFAULT ifnull(pnNotiID, 0);
  DECLARE vEmail        VARCHAR(255);
  DECLARE nChannelId BIGINT(20) DEFAULT 0;
  -- email count
  SET nCountEmail = LENGTH(pvMentionList) - LENGTH(REPLACE(pvMentionList, ',', '')) + 1;
  --
  IF nNotiID = 0 THEN
     --
     SELECT cn.email, cn.channel_id
       INTO vEmail, nChannelId
       FROM collection_notification cn
      WHERE cn.object_type = pvObjectType
        AND cn.object_uid = pvObjectUid
        AND cn.user_id = pnUserId
        LIMIT 1;
     -- only CALL for edit chat                                                                   
     SET nNotiID = c2024_createNotificationForChat(nChannelId, pnUserId, vEmail, pvObjectUid, pvObjectType, pvContent, pvMentionList, 31, pnActionTime, pnUpdatedDate);
     --
   END IF;
   -- nothing TO UPDATE
   IF nNotiID = 0 THEN
     --
     RETURN 0;
     --
   END IF;

 -- fix CASE empty WHEN mention ALL
 IF pvMentionList = '' THEN
   RETURN nNotiID;
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