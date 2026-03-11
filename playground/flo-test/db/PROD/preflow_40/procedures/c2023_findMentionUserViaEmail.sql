CREATE PROCEDURE `c2023_findMentionUserViaEmail`(
pvMentionText    VARCHAR(100)
,pvEmail         VARCHAR(100)
,OUT nUserId     BIGINT(20)
,OUT nReturn     INT(11)
)
c2023_findMentionUserViaEmail:BEGIN
  -- 1 find
  SELECT ifnull(max(mu.id), 0), mu.user_id
    INTO nReturn, nUserId
    FROM mention_user mu
   WHERE mu.email      = pvEmail
     AND mu.mention_text = pvMentionText;
  IF nReturn > 0 THEN
    --
    LEAVE c2023_findMentionUserViaEmail;
    --
  END IF;
  SELECT ifnull(max(uu.id), 0)
    INTO nUserId
    FROM `user` uu
   WHERE uu.username = pvEmail
     AND uu.disabled = 0;
  -- NOT found > inser
  INSERT INTO mention_user
  (mention_text, user_id, email, created_date, updated_date)
 VALUES(pvMentionText, nUserId, pvEmail, unix_timestamp(now(3)), unix_timestamp(now(3)));
  --
  SELECT LAST_INSERT_ID() INTO nReturn;
  --
END