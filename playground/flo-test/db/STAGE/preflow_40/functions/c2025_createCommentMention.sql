CREATE FUNCTION `c2025_createCommentMention`(pvMentionText   VARCHAR(100)
                                                     ,pvEmail          VARCHAR(100)
                                                     ,pnCommentId      INT(11)
                                                     ,pnUserId         BIGINT(20)
                                                     ,pbLast           TINYINT(1)
                                                     ,pnUpdatedDate    DOUBLE(13,3)) RETURNS INT
BEGIN
  --
  DECLARE nReturn           INT DEFAULT 0;
  DECLARE nCount            INT DEFAULT 0;
  DECLARE nMentionId        INT DEFAULT 0;
  DECLARE nNotiId           BIGINT(20) DEFAULT 0;
  DECLARE nCollectionId     BIGINT(20);
  DECLARE nPermission       TINYINT(1);
  DECLARE nUserId           BIGINT(20);
  DECLARE nMentionAll       TINYINT(1);
  DECLARE nTimestamp        DOUBLE(13,3);
  --
  -- USE provided updatedDate OR fallback TO current timestamp
  SET nTimestamp = IF(pnUpdatedDate > 0, pnUpdatedDate, unix_timestamp(now(3)));
  --
  -- 2. find mention_user id & CREATE IF NOT existed
  CALL c2023_findMentionUserViaEmail(pvMentionText, pvEmail, nUserId, nMentionId);
  --
  -- 3. INSERT comment_mention
  INSERT INTO comment_mention
    (comment_id, mention_user_id, created_date, updated_date)
  VALUES (pnCommentId, nMentionId, nTimestamp, nTimestamp);
  --
  SELECT LAST_INSERT_ID()
  INTO nReturn;
  --
  --
  SELECT ifnull(max(cn.id), 0), cn.collection_id, cm.mention_all
    INTO nNotiId, nCollectionId, nMentionAll
    FROM collection_notification cn
    JOIN collection_comment cm ON (cn.comment_id = cm.id)
   WHERE cn.comment_id = pnCommentId
     AND cm.action > 0; -- FOR updated
  --
  -- SET nPermission = c2023_checkCollectionPermission(nCollectionId, nUserId);
  -- IF nPermission < 1 THEN
    --
    -- RETURN -1;
    --
  -- END IF;
  --
  
  -- For CASE UPDATE comment, mention ALL do NOT CREATE noti user
  IF nMentionAll = 1 THEN
    RETURN nReturn;
  END IF;
  
  -- 
  IF nNotiId > 0 THEN
  --
   -- FB-5040 USE the updated_date FROM CREATE OR UPDATE comment instead the current timestamp.
   SET nReturn = n2024_considerMentionInNotification(nNotiID, pnCommentId, nTimestamp, nTimestamp);
  --
  END IF;
  --
  RETURN nReturn;
  --
END