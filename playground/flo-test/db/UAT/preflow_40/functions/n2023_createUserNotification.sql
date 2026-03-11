CREATE FUNCTION `n2023_createUserNotification`(pnNotiID       BIGINT(20)
,pnStatus       TINYINT(2) --   UNREAD = 0  READ = 1  CLOSED = 2
,pnHasMention   TINYINT(1)
,pdActionTime   DOUBLE(13,3)
,pnCreatedDate  DOUBLE(13,3)
,pnUpdatedDate  DOUBLE(13,3)
,pnDeletedDate  DOUBLE(13,3)
,pnUserID       BIGINT(20)
,pvEmail        VARCHAR(100)
) RETURNS INT
BEGIN
  --
  DECLARE nReturn        INT(11);
  DECLARE nID            INT(11);
  DECLARE nDeletedDate   DOUBLE(13,3);
  --
  SELECT ifnull(max(un.id), 0), ifnull(max(un.deleted_date), 0)
    INTO nID, nDeletedDate
    FROM user_notification un
   WHERE un.collection_notification_id = pnNotiID
     AND un.user_id = pnUserID;
  --
  IF nDeletedDate > 0 THEN
    --
    RETURN -1; -- NOT allow action IN deleted notification
    --
  END IF;
  --
  IF nID > 0 THEN
    -- UPDATE existing UN
    UPDATE user_notification un
        SET un.status        = ifnull(pnStatus, un.status)
           ,un.has_mention   = ifnull(pnHasMention, un.has_mention)
           ,un.updated_date  = ifnull(pnUpdatedDate, un.updated_date)
           ,un.action_time   = ifnull(pdActionTime, action_time)
           ,un.counted       = IF(pnStatus > 0, 1, 0)
           ,un.deleted_date  = ifnull(pnDeletedDate, deleted_date)
        WHERE un.id = nID;
    --
  ELSE
    -- CREATE new UN
    INSERT INTO user_notification
          (user_id, collection_notification_id, status, has_mention, action_time, counted, created_date, updated_date, deleted_date)
    VALUES
          (pnUserID, pnNotiID, pnStatus, ifnull(pnHasMention, 0), ifnull(pdActionTime, 0), IF(pnStatus > 0, 1, 0), pnUpdatedDate, pnUpdatedDate, pnDeletedDate);
    --
    SELECT last_insert_id() INTO nID;
    --
  END IF;
  -- decrease after READ|CLOSED notification (status=1)
  IF pnStatus > 0 THEN
    --
    SET nReturn = n2024_decreaseNotificationBadge(
        pnNotiID,
        pnUpdatedDate,
        pnUpdatedDate,
        pnUserID,
        pvEmail
      );
    --
  END IF;
  --
  RETURN nID;
  --
END