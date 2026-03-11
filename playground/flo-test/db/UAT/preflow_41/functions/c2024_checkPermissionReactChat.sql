CREATE FUNCTION `c2024_checkPermissionReactChat`(pnChannelId           BIGINT(20)
                                                                   ,pnUserId              BIGINT(20)
                                                                   ) RETURNS DOUBLE
BEGIN
  -- CHECK permisstion TO react chat
  # -1. Invalid param
  #  0. NOT allow TO reacta
  #  1. allow TO react
  #  timestamp. - this IS join_date,  need CHECK WITH message's created_date >= join_date
  --
  DECLARE nReturn         TINYINT(1) DEFAULT 0;
  
  -- 0. collection id = 0 aka omni
  IF ifnull(pnChannelId, 0) = 0 OR ifnull(pnUserId, 0) = 0 THEN
    --
    RETURN -1;
    --
  END IF;
  --
  SELECT ifnull(max(cm.id), 0) > 0
    INTO nReturn
    FROM conference_member cm
    JOIN conference_channel cc ON (cm.channel_id = cc.id)
   WHERE cc.id = pnChannelId
     AND cm.user_id = pnUserId
     AND cm.revoke_time = 0
     ;
  --
  RETURN nReturn;
  --
END