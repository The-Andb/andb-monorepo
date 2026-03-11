CREATE PROCEDURE `u2025_upsertUserUsageWarning`(
  pnComValue       BIGINT,
  pnComponentId   BIGINT,
  pnUserId        BIGINT
)
u2025_upsertUserUsageWarning: BEGIN
  --
  DECLARE nID           BIGINT(20);
  DECLARE nLimit        BIGINT(20);
  DECLARE nPercent      INT;
  DECLARE nThreshold    INT;
  --
  -- Skip IF user_id invalid, stop process REACH
  IF IFNULL(pnUserId, 0) = 0 THEN
    LEAVE u2025_upsertUserUsageWarning;
  END IF;
  --
  -- GET LIMIT BY plan
  SELECT od.component_value
    INTO nLimit
    FROM order_details od
    JOIN orders ord ON ord.id = od.order_id
   WHERE od.component_id = pnComponentId
     AND ord.user_id = pnUserId
     AND ord.is_active = 1
   LIMIT 1;
  --
  -- CHECK unlimited
  IF nLimit = -1 THEN
    LEAVE u2025_upsertUserUsageWarning;
  END IF;
  --
  -- GET threshold percent
  SELECT cl.threshold
    INTO nThreshold
    FROM component_limits cl
   WHERE cl.component_id    = pnComponentId;
  --
  -- Calculate USAGE percent
  SET nPercent = (pnComValue / nLimit) * 100;
  --
  -- CHECK IF warning EXISTS
  SELECT IFNULL(MAX(uw.id), 0)
    INTO nID
    FROM user_usage_warnings uw
   WHERE uw.user_id = pnUserId
     AND uw.component_id    = pnComponentId
     AND uw.limit_type      = 'REACH';
  --
  IF nID = 0 THEN
    -- INSERT warning IF over threshold
    IF nPercent >= nThreshold THEN
      INSERT INTO user_usage_warnings
      (user_id,     component_id,   limit_type, percent, `value`, `LIMIT`)
      VALUES
      (pnUserId,    pnComponentId, 'REACH', nPercent, pnComValue, nLimit);
    END IF;
    --
  ELSE
    -- UPDATE existing warning
    IF nPercent >= nThreshold THEN
      -- Over threshold → UPDATE percent + timestamp
      UPDATE user_usage_warnings
         SET percent = nPercent
            ,`value` = pnComValue
            ,`LIMIT` = nLimit
            ,updated_date = NOW(3)
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