CREATE TRIGGER `AFTER_INSERT_CSM` AFTER INSERT ON `collection_shared_member` FOR EACH ROW BEGIN
 --
 DECLARE vOwnerUri          VARCHAR(255);
 DECLARE vOwnerUsername     VARCHAR(255);
 DECLARE nChannelId      BIGINT(20) DEFAULT 0;
 --
 SELECT co.calendar_uri, co.channel_id, u.username
   INTO vOwnerUri, nChannelId, vOwnerUsername
    FROM collection co
    JOIN user u ON co.user_id = u.id
   WHERE co.id = NEW.collection_id;
  --
  INSERT INTO collection_notification_member 
           (collection_id, calendarid, channel_id, access
            ,member_calendar_uri, member_email, member_user_id
            ,owner_calendar_uri ,owner_email, owner_user_id
            ,fk_collection_id, fk_channel_id, fk_cm_id, fk_csm_id, is_active
            ,created_date, updated_date)
    VALUES
            (NEW.collection_id,0 -- will supply after calendarinstances
            ,nChannelId, NEW.access
            ,NEW.calendar_uri, NEW.shared_email, NEW.member_user_id
            ,vOwnerUri, vOwnerUsername, NEW.user_id
            ,NEW.collection_id, nChannelId, NULL, NEW.id, 0
            ,UNIX_TIMESTAMP(now(3)), UNIX_TIMESTAMP(now(3)));
 --
END