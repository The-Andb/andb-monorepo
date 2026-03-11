CREATE FUNCTION `OTE_generateCollectionNotificationMemberTrashed`(
   pnUserId           BIGINT(20)
  ,pnCollectionId     BIGINT(20) 
  ,pnChannelId        BIGINT(20)
  ) RETURNS TINYINT
BEGIN
  -- INSERT user roles INTO cache TABLE
  INSERT INTO collection_notification_member 
  (collection_id, calendarid, channel_id
   ,member_calendar_uri, member_email, member_user_id
   ,owner_calendar_uri ,owner_email, owner_user_id
   ,fk_collection_id, fk_channel_id, fk_cm_id, fk_csm_id, is_active
   ,created_date, updated_date)
  
  -- 1. Owner roles
  SELECT co.id AS collection_id, 0 calendarid
        ,ifnull(co.channel_id, 0) channel_id
        ,co.calendar_uri member_calendar_uri, usr.username member_email, co.user_id member_user_id
        ,co.calendar_uri owner_calendar_uri, usr.username owner_email, co.user_id owner_user_id
        ,co.id fk_collection_id
        ,NULL fk_channel_id
        ,NULL fk_cm_id
        ,NULL fk_csm_id
        ,0 is_active
        ,unix_timestamp() AS created_date
        ,unix_timestamp() AS updated_date
    FROM collection co
--     JOIN calendarinstances ci ON (co.calendar_uri = ci.uri)
    JOIN user usr ON co.user_id = usr.id
LEFT JOIN collection_notification_member cnm ON (cnm.collection_id = co.id AND cnm.channel_id = co.channel_id AND cnm.member_user_id = co.user_id)
   WHERE (pnUserId IS NULL OR co.user_id = pnUserId)
     AND (pnCollectionId IS NULL OR co.id = pnCollectionId)
     AND ifnull(co.is_trashed, 0) = 1
     AND co.user_id > 0
     AND co.type = 3
  UNION 
  
  -- 2. Shared member roles
  SELECT co.id AS collection_id, 0 calendarid
        ,co.channel_id
        ,csm.calendar_uri member_calendar_uri, csm.shared_email member_email, csm.member_user_id
        ,co.calendar_uri owner_calendar_uri, usr.username owner_email, co.user_id owner_user_id
        ,co.id fk_collection_id
        ,NULL fk_channel_id
        ,NULL fk_cm_id
        ,csm.id fk_csm_id
        ,0 is_active
        ,unix_timestamp() AS created_date
        ,unix_timestamp() AS updated_date
    FROM collection_shared_member csm
    JOIN collection co ON (csm.collection_id = co.id)
--     JOIN calendarinstances ci ON (co.calendar_uri = ci.uri)
    JOIN user usr ON co.user_id = usr.id
    LEFT JOIN collection_notification_member cnm ON (cnm.collection_id = co.id AND cnm.channel_id = co.channel_id AND cnm.member_user_id = csm.member_user_id)
   WHERE (pnUserId IS NULL OR csm.member_user_id = pnUserId)
     AND (pnCollectionId IS NULL OR co.id = pnCollectionId)
     AND ifnull(co.is_trashed, 0) = 1
     AND csm.shared_status = 1
     AND co.type = 3
     AND csm.member_user_id > 0
  UNION 
  -- 3. Conference member roles
  SELECT ifnull(cc.collection_id, 0) collection_id, 0 calendarid
        ,cm.channel_id
        ,'' COLLATE utf8mb4_0900_ai_ci member_calendar_uri, cm.email member_email, cm.user_id member_user_id
        ,'' COLLATE utf8mb4_0900_ai_ci owner_calendar_uri,'' COLLATE utf8mb4_0900_ai_ci owner_email, 0 owner_user_id
        ,cc.collection_id fk_collection_id
        ,cm.channel_id fk_channel_id
        ,cm.id fk_cm_id
        ,NULL fk_csm_id
        ,0 is_active
        ,unix_timestamp() AS created_date
        ,unix_timestamp() AS updated_date
     FROM conference_member cm
    JOIN conference_channel cc ON (cc.id = cm.channel_id)
    JOIN `user` u ON (u.id = cm.user_id)
     LEFT JOIN collection_notification_member cnm ON (cnm.collection_id = cc.collection_id AND cnm.channel_id = cc.id AND cnm.member_user_id = cm.user_id)
   WHERE (pnUserId IS NULL OR cm.user_id = pnUserId)
     AND (pnCollectionId IS NULL OR cc.collection_id = pnCollectionId)
     AND (pnChannelId IS NULL OR cc.id = pnChannelId)
     AND ifnull(cc.collection_id, 0) = 0
     AND cc.is_trashed = 1
     AND cm.revoke_time = 0
     AND cm.user_id > 0
     
  ON DUPLICATE KEY UPDATE 
      is_active = VALUES(is_active),
      updated_date = unix_timestamp();
   
  RETURN 1;
END