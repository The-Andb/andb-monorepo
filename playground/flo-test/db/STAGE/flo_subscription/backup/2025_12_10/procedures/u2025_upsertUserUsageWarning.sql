CREATE PROCEDURE `u2025_upsertUserUsageWarning`(
  pnNewComValue       BIGINT,
  pnOldComValue       BIGINT,
  pnComponentId       BIGINT,
  pnUserId            BIGINT
)
u2025_upsertUserUsageWarning: BEGIN
  --
  DECLARE nID           BIGINT(20);
  DECLARE nLimit        BIGINT(20);
  DECLARE nNewPercent   INT;
  DECLARE nOldPercent   INT;
  DECLARE nThreshold    INT;
  DECLARE nNumsent      INT;
  DECLARE nResetTier    INT;
  DECLARE nNewNumSent    INT;
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
  IF nLimit IS NULL THEN
    LEAVE u2025_upsertUserUsageWarning;
  END IF;

  -- CHECK unlimited
  IF nLimit = -1 THEN
    LEAVE u2025_upsertUserUsageWarning;
  END IF;

  -- GET threshold percent
  SELECT cl.threshold
    INTO nThreshold
    FROM component_limits cl
   WHERE cl.component_id = pnComponentId;
  -- Calculate USAGE percent
  -- SET nOldPercent = Floor(CAST(pnOldComValue AS DOUBLE) / CAST(nLimit AS DOUBLE) * 100);
  SET nNewPercent = Floor(CAST(pnNewComValue AS DOUBLE) / CAST(nLimit AS DOUBLE) * 100);
  -- CHECK existing warning
  SELECT IFNULL(MAX(uw.id), 0), IFNULL(MAX(uw.num_sent), 0)
    INTO nID, nNumsent
    FROM user_usage_warnings uw
   WHERE uw.user_id     = pnUserId
     AND uw.component_id= pnComponentId
     AND uw.limit_type  = 'REACH';
     
  -- RESET TIER LOGIC
  IF nNewPercent < 80 THEN
    SET nResetTier = -1;   -- DELETE
  ELSEIF nNewPercent < 95 THEN -- 80-95
    SET nResetTier = 0;
  ELSEIF nNewPercent < 100 THEN -- 95-100
    SET nResetTier = 1;
  ELSE
      SET nResetTier = 2;
  END IF;
  -- num_sent rule (new logic)
  SET nNewNumSent = IF(nResetTier < 0, -1, GREATEST(nResetTier, nNumSent));
  -- INSERT IF NO RECORD
  IF nID = 0 AND nResetTier > -1 THEN
    --
    INSERT INTO user_usage_warnings
      (user_id, component_id, limit_type, percent, `value`, `LIMIT`, num_sent)
    VALUES
      (pnUserId, pnComponentId, 'REACH',
       nNewPercent, pnNewComValue, nLimit, nResetTier);
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