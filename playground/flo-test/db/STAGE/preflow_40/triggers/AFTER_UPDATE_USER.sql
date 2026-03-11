CREATE TRIGGER `AFTER_UPDATE_USER` AFTER UPDATE ON `user` FOR EACH ROW BEGIN
  --
  IF NEW.disabled <> OLD.disabled THEN
    --
    UPDATE collection_notification_member cnm
       SET cnm.is_active = IF(NEW.disabled = 0, 1, 0)
     WHERE cnm.member_user_id = OLD.id;
   END IF;
  --
END