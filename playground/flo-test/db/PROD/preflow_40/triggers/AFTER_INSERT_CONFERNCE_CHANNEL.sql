CREATE TRIGGER `AFTER_INSERT_CONFERNCE_CHANNEL` AFTER INSERT ON `conference_channel` FOR EACH ROW BEGIN
 --
 IF NEW.collection_id IS NOT NULL THEN
   --
   UPDATE collection_notification_member cnm
      SET cnm.channel_id        = NEW.id
         ,cnm.fk_channel_id     = NEW.id
    WHERE cnm.collection_id     = NEW.collection_id
      AND cnm.member_user_id    = NEW.user_id;
   --
 END IF;
 --
END