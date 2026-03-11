CREATE PROCEDURE `p2024_getPlatformSetting4APNs`(pvUsername  VARCHAR(100))
BEGIN
  --
  SELECT psi.id, psi.user_id, psi.app_reg_id, psi.incoming_mail, psi.incoming_call, psi.filter_chat
    FROM platform_setting_instance psi
    JOIN `user` u ON (psi.user_id = u.id)
    WHERE u.username = pvUsername
    AND psi.app_reg_id IN (
            'ad944424393cf309efaf0e70f1b125cb', -- MAC
            'faf0e70f1bad944424393cf309e125cb', -- iPhone
            'd944424393cf309e125cbfaf0e70f1ba' -- iPad
        )
  ;
  --
END