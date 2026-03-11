CREATE PROCEDURE `d2023_listOfDeviceTokenByEmail`(pvUsername      VARCHAR(100)
                                                                     ,voip           TINYINT(1))
d2023_listOfDevice : BEGIN
  --
  --  0 THEN 'FLO_INTERNAL' -- IPHONE
  --  1 THEN 'FLO_IPAD_QC'
  --  2 THEN 'FLO_IPAD_PROD'
  --  3 THEN 'FLO_IPHONE_QC'
  --  4 THEN 'FLO_IPHONE_DEV'
  --
  DECLARE nCursor       INT DEFAULT 1;
  DECLARE vDelimiter    VARCHAR(1) DEFAULT ',';
  DECLARE vDeviceType   VARCHAR(20);
  --
  IF isnull(pvUsername) THEN
    --
    LEAVE d2023_listOfDevice;
    --
  END IF;
  --
  SET vDeviceType = '0,1,2,3,4,5,6'; -- 'IPAD' THEN '1,2' -- 'IPHONE' THEN '0,3,4' -- 'MAC' THEN 5,6
  --
 SELECT u.username, dt.device_type, dt.device_uuid device_uid, dt.device_token, dt.user_id, dt.cert_env, dt.env_silent
 -- ta.app_id, ta.app_version, ta.flo_version, ta.build_number        
    FROM  device_token dt
    JOIN user u ON (u.id = dt.user_id)
  --  LEFT JOIN access_token act ON (dt.device_token = act.device_token AND u.id = act.user_id)
  --  LEFT JOIN user_tracking_app uta ON (uta.user_id = u.id)
   -- LEFT JOIN tracking_app ta ON (ta.id = uta.tracking_app_id)
   WHERE dt.device_type IN (0,1,2,3,4,5,6)
     AND (dt.device_type IN (5,6) -- always GET MAC tokens NOT depend ON VoIP
          OR CASE 
             WHEN ifnull(voip, 0) = 1 
              THEN dt.cert_env IN (2, 3) 
             ELSE dt.cert_env IN (1, 0)
            END)
     AND ifnull(u.disabled, 0) = 0
    -- AND act.app_id <> 'e70f1b125cbad944424393cf309efaf0' -- NOT WEB
    -- AND ifnull(act.is_revoked, 0) = 0
    -- AND act.expires_in > FLOOR(UNIX_TIMESTAMP(NOW(3) - INTERVAL 1 hour) * 1000) -- time IN seconds, living & buffer 1h
     AND u.username = pvUsername
   --  AND ta.build_number > 0
     GROUP BY dt.id;
  --
  --
END