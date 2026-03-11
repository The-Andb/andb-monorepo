CREATE TRIGGER `AFTER_INSERT_USER` AFTER INSERT ON `user` FOR EACH ROW BEGIN
 --
   INSERT INTO collection_notification_member 
         (collection_id, calendarid, channel_id
          ,member_calendar_uri, member_email, member_user_id
          ,owner_calendar_uri ,owner_email, owner_user_id
          ,fk_collection_id, fk_channel_id, fk_cm_id, fk_csm_id, is_active
          ,created_date, updated_date)
   VALUES
          (0
          ,0 -- will supply after calendarinstances
          ,0 -- will supply after channel created
          ,'', NEW.email, NEW.id
          ,'', NEW.email, NEW.id
          ,NEW.id, NULL, NULL, NULL, 1
          ,UNIX_TIMESTAMP(now(3)), UNIX_TIMESTAMP(now(3)));
 --
END