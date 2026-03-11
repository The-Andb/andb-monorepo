CREATE PROCEDURE `u2025_upsertUserUsageWarning`(
  pnNewComValue       BIGINT,
  pnOldComValue       BIGINT,
  pnComponentId       BIGINT,
  pnUserId            BIGINT
)
u2025_upsertUserUsageWarning: BEGIN
  --
  DECLARE nID             BIGINT(20);
  DECLARE nLimit          BIGINT(20);
  DECLARE nNewPercent     INT;
  DECLARE nOldPercent     INT;
  DECLARE nNumsent        INT;
  DECLARE nResetTier      INT;
  DECLARE nOldTier        INT;
  DECLARE nNewNumSent     INT;
  DECLARE nMaxSentForTier INT;
  --
  -- Skip IF user_id invalid, stop process REACH
  IF IFNULL(pnUserId, 0) = 0 THEN
    LEAVE u2025_upsertUserUsageWarning;
  END IF;

  -- GET LIMIT BY plan
  SELECT max(od.component_value)
    INTO nLimit
    FROM order_details od
    JOIN orders ord ON (ord.id = od.order_id)
   WHERE od.component_id = pnComponentId
     AND ord.user_id     = pnUserId
     AND ord.is_active   = 1
   LIMIT 1;
   
  -- Skip IF user_id NOT found
  -- CHECK unlimited
  IF nLimit IS NULL OR nLimit = -1 THEN
    LEAVE u2025_upsertUserUsageWarning;
  END IF;

  -- Calculate USAGE percent
  SET nOldPercent = Floor(CAST(pnOldComValue AS DOUBLE) / CAST(nLimit AS DOUBLE) * 100);
  SET nNewPercent = Floor(CAST(pnNewComValue AS DOUBLE) / CAST(nLimit AS DOUBLE) * 100);
  -- CHECK existing warning
  SELECT IFNULL(MAX(uw.id), 0), IFNULL(MAX(uw.num_sent), 0)
    INTO nID, nNumsent
    FROM user_usage_warnings uw
   WHERE uw.user_id      = pnUserId
     AND uw.component_id = pnComponentId
     AND uw.limit_type   = 'REACH';
-- ----------------------------
  -- RESET TIER LOGIC
  IF nNewPercent < 80 THEN
    SET nResetTier = -1;
  ELSEIF nNewPercent < 95 THEN
    SET nResetTier = 0;
  ELSEIF nNewPercent < 100 THEN
    SET nResetTier = 1;
  ELSE
    SET nResetTier = 2;
  END IF;

  -- OLD TIER
  IF nOldPercent < 80 THEN
    SET nOldTier = -1;
  ELSEIF nOldPercent < 95 THEN
    SET nOldTier = 0;
  ELSEIF nOldPercent < 100 THEN
    SET nOldTier = 1;
  ELSE
    SET nOldTier = 2;
  END IF;

  -- num_sent logic
  SET nMaxSentForTier = nResetTier + 1;

  IF nResetTier < 0 THEN
    SET nNewNumSent = -1;
  ELSEIF nResetTier > nOldTier THEN
    -- Incr tier: skip mail slower tier
    SET nNewNumSent = GREATEST(nResetTier, nNumSent);
  ELSE
    -- Decr/keep tier: back TO max current tier
    SET nNewNumSent = LEAST(nMaxSentForTier, nNumSent);
  END IF;
-- ----------------------------
  -- INSERT IF NO RECORD
  IF nID = 0 AND nResetTier > -1 THEN
    --
    INSERT INTO user_usage_warnings
      (user_id, component_id, limit_type, percent, old_percent, `value`, `LIMIT`, num_sent)
    VALUES
      (pnUserId, pnComponentId, 'REACH', nNewPercent, nOldPercent, pnNewComValue, nLimit, nResetTier);
    --
  ELSE
    -- UPDATE EXISTING RECORD
    -- num_sent = max(old, resetTier)
     IF nResetTier = -1 THEN
       -- DELETE record
       DELETE FROM user_usage_warnings
             WHERE id = nID;
        LEAVE u2025_upsertUserUsageWarning;
        --
      ELSE
        --
        UPDATE user_usage_warnings
           SET percent      = nNewPercent
              ,old_percent  = nOldPercent
              ,`value`      = pnNewComValue
              ,`LIMIT`      = nLimit
              ,num_sent     = nNewNumSent
              ,updated_date = NOW(3)
         WHERE id = nID;
        --
      END IF;
    --
  END IF;
  --
END