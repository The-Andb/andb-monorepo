CREATE PROCEDURE `d2024_listOfSilentDeviceTokenByUserId`(pnUserId      BIGINT(20)
                                                                           ,voip           TINYINT(1))
d2023_listOfDevice : BEGIN
  --
  --  0 THEN 'FLO_INTERNAL' -- IPHONE
  --  1 THEN 'FLO_IPAD_QC'
  --  2 THEN 'FLO_IPAD_PROD'
  --  3 THEN 'FLO_IPHONE_QC'
  --  4 THEN 'FLO_IPHONE_DEV'
  --
  IF isnull(pnUserId) THEN
    --
    LEAVE d2023_listOfDevice;
    --
  END IF;
  --
 SELECT dt.id, dt.user_id, dt.device_token, dt.env_silent, CONCAT(dt.device_type, dt.cert_env) pem    
    FROM  device_token dt
    JOIN user u ON (u.id = dt.user_id)
   WHERE dt.device_type IN (0,1,2,3,4,5,6) -- 'IPAD' THEN '1,2' -- 'IPHONE' THEN '0,3,4' -- 'MAC' THEN 5,6
     AND dt.cert_env IN (1, 0) -- always GET normal device token
     AND (u.disabled IS NULL OR u.disabled = 0)
     AND u.id = pnUserId
     GROUP BY dt.id;
  --
END