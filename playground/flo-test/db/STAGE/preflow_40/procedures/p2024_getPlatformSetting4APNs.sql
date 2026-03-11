CREATE PROCEDURE `p2024_getPlatformSetting4APNs`(pvUsername  VARCHAR(100))
BEGIN
  --
  WITH app_list (app_reg_id) AS (
    SELECT 'ad944424393cf309efaf0e70f1b125cb'
    UNION
    SELECT 'faf0e70f1bad944424393cf309e125cb'
    UNION
    SELECT 'd944424393cf309e125cbfaf0e70f1ba'
)
SELECT u.id AS user_id, al.app_reg_id
      ,IFNULL(psi.id, 0) AS id
      ,IFNULL(psi.incoming_mail, 0) AS incoming_mail
      ,IFNULL(psi.incoming_call, 0) AS incoming_call
      ,IFNULL(psi.filter_chat, 0) AS filter_chat
  FROM `user` u
 CROSS JOIN app_list al
  LEFT JOIN (
    SELECT psi1.user_id, psi1.app_reg_id, psi1.id
          ,psi1.incoming_mail, psi1.incoming_call, psi1.filter_chat
      FROM platform_setting_instance psi1
     WHERE psi1.id = (
        SELECT MAX(psi2.id) 
          FROM platform_setting_instance psi2
         WHERE psi2.user_id = psi1.user_id 
           AND psi2.app_reg_id = psi1.app_reg_id
    )
) psi ON psi.user_id = u.id AND psi.app_reg_id = al.app_reg_id
 WHERE u.username = pvUsername;
  --
END