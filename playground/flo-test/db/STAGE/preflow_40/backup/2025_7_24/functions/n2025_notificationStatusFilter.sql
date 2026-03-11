CREATE FUNCTION `n2025_notificationStatusFilter`(
pvStatusFilter     VARCHAR(100)
,pnStatus                  INT
,pnCreatedDate      DOUBLE(13,3)
) RETURNS TINYINT(1)
BEGIN
  --
  DECLARE nStatus TINYINT(1) DEFAULT ifnull(pnStatus, 0);
  DECLARE nNew    TINYINT(1) DEFAULT find_in_set(1, pvStatusFilter);
  --
  RETURN IF(find_in_set(1, pvStatusFilter), unix_timestamp(now(3) - INTERVAL 1 day) <= pnCreatedDate, 1)
       AND (
            ((pvStatusFilter = '1' OR find_in_set(0, pvStatusFilter)) AND nStatus IN (0, 1, 2))
         OR (find_in_set(2, pvStatusFilter) AND nStatus = 1)
         OR (find_in_set(3, pvStatusFilter) AND nStatus = 0)
         OR (find_in_set(4, pvStatusFilter) AND nStatus = 2)
       );
  --
END