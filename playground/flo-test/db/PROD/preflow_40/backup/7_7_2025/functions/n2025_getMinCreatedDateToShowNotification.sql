CREATE FUNCTION `n2025_getMinCreatedDateToShowNotification`(pnUserId BIGINT(20)) RETURNS DOUBLE
BEGIN
  --
  DECLARE nReturn DOUBLE;
  --
  SELECT IF(st.notification_clean_date <= 0
        ,UNIX_TIMESTAMP(NOW(3) - INTERVAL 365 DAY)
        ,UNIX_TIMESTAMP(NOW(3)) - st.notification_clean_date)
    INTO nReturn
    FROM setting st
   WHERE st.user_id = pnUserId;
  --
  RETURN nReturn;
  --
END