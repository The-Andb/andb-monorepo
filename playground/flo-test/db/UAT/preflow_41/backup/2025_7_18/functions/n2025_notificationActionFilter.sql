CREATE FUNCTION `n2025_notificationActionFilter`(
pvActionFilter     VARCHAR(100)
,pnAction            INT
,pnHasMention       TINYINT(1)
) RETURNS TINYINT(1)
BEGIN
  --
  IF isnull(pvActionFilter) THEN 
     RETURN 1;
  END IF;
  -- other action
  RETURN find_in_set(-1, pvActionFilter) AND pnAction NOT IN (0, 1, 4, 41, 6, 61, 63, 13, 23, 24, 30, 33)
         -- find exactly action
         OR find_in_set(pnAction, pvActionFilter)
           -- for comment
           OR CASE 
                WHEN find_in_set(6, pvActionFilter)
                THEN (pnAction = 61 AND pnHasMention = 1) OR pnAction = 63 OR find_in_set(pnAction, pvActionFilter)
                WHEN find_in_set(63, pvActionFilter)
                THEN pnHasMention = 1 AND pnAction IN (6, 61)
              END 
           -- for chat
           OR CASE 
                WHEN find_in_set(30, pvActionFilter)
                THEN (pnAction = 31 AND pnHasMention = 1) OR pnAction = 33 OR find_in_set(pnAction, pvActionFilter)
                WHEN find_in_set(33, pvActionFilter)
                THEN pnHasMention = 1 AND pnAction IN (30, 31)
              END;
  --
END