CREATE FUNCTION `c2023_createCommentMentionV2`(pvMentionText   VARCHAR(100)
                                                     ,pvEmail           VARCHAR(100)
                                                     ,pnCommentId      INT(11)
                                                     ,pnUserId         BIGINT(20)
                                                     ,pbLast          TINYINT(1)) RETURNS INT(11)
BEGIN
  --
  DECLARE nReturn           INT DEFAULT 0;
  DECLARE nCount            INT DEFAULT 0;
  DECLARE nMentionId        INT DEFAULT 0;
  DECLARE nNotiId           BIGINT(20) DEFAULT 0;
  DECLARE nCollectionId     BIGINT(20);
  DECLARE nPermistion       TINYINT(1);
  DECLARE nUserId           BIGINT(20);
  --
  -- 2. find mention_user id & CREATE IF NOT existed
  CALL c2023_findMentionUserViaEmail(pvMentionText, pvEmail, nUserId, nMentionId);
  --
  -- 3. INSERT comment_mention
  INSERT INTO comment_mention
    (comment_id, mention_user_id, created_date, updated_date)
  VALUES (pnCommentId, nMentionId, unix_timestamp(now(3)), unix_timestamp(now(3)));
  --
  SELECT LAST_INSERT_ID()
  INTO nReturn;
  --
  --
  SELECT ifnull(max(cn.id), 0), cn.collection_id
    INTO nNotiId, nCollectionId
    FROM collection_notification cn
    JOIN collection_comment cm ON (cn.comment_id = cm.id)
   WHERE cn.comment_id = pnCommentId
     AND cm.action > 0; -- FOR updated
  --
  -- SET nPermistion = c2023_checkCollectionPermistion(nCollectionId, nUserId);
  -- IF nPermistion < 1 THEN
    --
    -- RETURN -1;
    --
  -- END IF;
  --
  IF nNotiId > 0 THEN
    --
    SET nReturn = n2024_considerMentionInNotification(nNotiID, pnCommentId, unix_timestamp(now(3)), unix_timestamp(now(3)));
    --
  END IF;
  --
  RETURN nReturn;
  --
END