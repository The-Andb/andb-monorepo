CREATE PROCEDURE `u2025_upsertUserAlertWarning`(
  pnComValue       BIGINT,
  pnComponentId   BIGINT,
  pvLimitType     ENUM('NORMAL', 'EXPIRED', 'REACH', 'EXCEED') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  pdLimitAt      TIMESTAMP(3),
  pnUserId        BIGINT
)
u2025_upsertUserAlertWarning: BEGIN
  --
  DECLARE nID           BIGINT(20);
  DECLARE nLimit        BIGINT(20);
  --
  -- Skip IF user_id invalid, stop process WHEN NOT EXCEED
  IF IFNULL(pnUserId, 0) = 0 OR pvLimitType <> 'EXCEED' THEN
    LEAVE u2025_upsertUserAlertWarning;
  END IF;
  -- CHECK IF warning EXISTS
  SELECT IFNULL(MAX(uw.id), 0)
    INTO nID
    FROM user_usage_warnings uw
   WHERE uw.user_id = pnUserId
     AND uw.component_id    = pnComponentId
     AND uw.limit_type      = pvLimitType;
  --
  IF nID = 0 THEN
    -- INSERT warning IF over threshold
    INSERT INTO user_usage_warnings
    (user_id,     component_id,   limit_type, percent, `value`, `LIMIT`, expire_at)
    VALUES
    (pnUserId,    pnComponentId, pvLimitType, 0, pnComValue, 1, pdLimitAt);
    --
  ELSE
    -- UPDATE existing warning
    IF pnComValue = 1 THEN
      -- Over threshold → UPDATE percent + timestamp
      UPDATE user_usage_warnings
         SET updated_date = NOW(3)
       WHERE id = nID;
    ELSE
      -- Below threshold → reset percent
      DELETE FROM user_usage_warnings
       WHERE id = nID;
    END IF;
    --
  END IF;
  --
END