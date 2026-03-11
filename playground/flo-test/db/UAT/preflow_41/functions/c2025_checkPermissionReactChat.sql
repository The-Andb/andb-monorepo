CREATE FUNCTION `c2025_checkPermissionReactChat`(pnChannelId           BIGINT(20)
                                                                   ,pnUserId              BIGINT(20)
                                                                   ,pvMessageUid         VARCHAR(100)  CHARACTER SET latin1 COLLATE latin1_swedish_ci
                                                                   ) RETURNS DOUBLE
BEGIN
  -- CHECK permisstion TO react chat
  # Round 1. CHECK WITH channel_id only (messageUid= NULL)
  # Round 2. CHECK WITH pvMessageUid WHEN the value which RETURN FROM round 1 IS gt 1 (#4 join_date)
  #1 -1. Invalid param
  #2  0. NOT allow TO react
  #3  1. allow TO react
  #4  timestamp. - this IS join_date,  need CHECK WITH message's created_date >= join_date
  --
  DECLARE nReturn           TINYINT(1) DEFAULT 0;
  DECLARE nViewHistory      TINYINT(1) DEFAULT 0;
  DECLARE nJoinDate         DOUBLE(13,3) DEFAULT 0;
  DECLARE nCreatedDate      DOUBLE(13,3) DEFAULT 0;
  DECLARE vFileUid         TEXT;
  DECLARE vQuoteMessageUid  TEXT;
  DECLARE vContent         TEXT;
  -- 0. collection id = 0 aka omni
  IF ifnull(pnChannelId, 0) = 0 OR ifnull(pnUserId, 0) = 0 THEN
    --
    RETURN -1;
    --
  END IF;
  -- R2
  IF NOT isnull(pvMessageUid) AND pvMessageUid <> '' THEN
    --
    SELECT rm.created_date,
       rm.content,
       ifnull(JSON_UNQUOTE(JSON_EXTRACT(rm.metadata, '$.attachments[0].file_uid')), ''),
           ifnull(JSON_UNQUOTE(JSON_EXTRACT(rm.message_marked, '$.message_uid')), '')
      INTO nCreatedDate, vContent, vFileUid, vQuoteMessageUid
      FROM realtime_message rm
     WHERE rm.uid = pvMessageUid
       AND rm.type = 'CHAT';
    --
  END IF;
  -- NOT allow TO react the message that NOT uploaded success
  -- Allow TO react TO quote message which content IS empty
  IF vContent = '' AND vFileUid = '' AND vQuoteMessageUid = '' THEN
    --
    RETURN 0;
    --
  END IF;
  -- R1
  SELECT ifnull(max(cm.id), 0) > 0, ifnull(cm.view_chat_history, 0), cm.join_time
    INTO nReturn, nViewHistory, nJoinDate
    FROM conference_member cm
    JOIN conference_channel cc ON (cm.channel_id = cc.id)
   WHERE cc.id = pnChannelId
     AND cm.user_id = pnUserId
     AND cm.revoke_time = 0
     ;
  --
  IF nReturn > 0 AND nViewHistory = 0 THEN
    --
    IF nCreatedDate > 0 THEN
      RETURN nCreatedDate >= nJoinDate;
    ELSE
      RETURN nJoinDate;
    END IF;
    --
  END IF;
  --
  RETURN nReturn;
  --
END