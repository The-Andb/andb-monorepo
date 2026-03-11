CREATE FUNCTION `n2025_getMinCreatedDateToShowNotification`(pnUserId BIGINT(20)) RETURNS DOUBLE
BEGIN
  --
  DECLARE nReturn DOUBLE;
  --
  SELECT CASE 
           -- max SHOW notification 365 days
           WHEN st.notification_clean_date <= 0 THEN 
             UNIX_TIMESTAMP(NOW(3) - INTERVAL 30 DAY)
           -- END of day
           WHEN st.notification_clean_date = 1 THEN 
             UNIX_TIMESTAMP(DATE(NOW(3)))
           -- DEFAULT follow setting
           ELSE 
             UNIX_TIMESTAMP(NOW(3)) - st.notification_clean_date
         END
    INTO nReturn
    FROM setting st
   WHERE st.user_id = pnUserId;
  --
  RETURN nReturn;
  --
END