CREATE FUNCTION `n2025_notificationStatusFilter`(
pvStatusFilter     VARCHAR(100)
,pnStatus                  INT
,pnCreatedDate      DOUBLE(13,3)
) RETURNS TINYINT(1)
BEGIN
  --
  RETURN (find_in_set(0, pvStatusFilter)
         OR (-- 1: New
             IF(find_in_set(1, pvStatusFilter), unix_timestamp(now(3) - INTERVAL 1 day) <= pnCreatedDate, 1)
             -- 2: READ
             AND IF(find_in_set(2, pvStatusFilter), pnStatus = 1, 1)
             -- 3: Unread
             AND IF(find_in_set(3, pvStatusFilter), pnStatus = 0, 1)
             -- 4: Closed
             AND IF(find_in_set(4, pvStatusFilter), ifnull(pnStatus, 0) = 2, 1)
           )
       );
  --
END