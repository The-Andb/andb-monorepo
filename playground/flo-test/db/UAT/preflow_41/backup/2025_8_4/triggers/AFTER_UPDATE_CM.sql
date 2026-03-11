CREATE TRIGGER `AFTER_UPDATE_CM` AFTER UPDATE ON `conference_member` FOR EACH ROW BEGIN
  --
  IF OLD.revoke_time <> NEW.revoke_time THEN
    --
    UPDATE collection_notification_member cnm
       SET cnm.is_active = IF(NEW.revoke_time = 0, 1, 0)
     WHERE cnm.channel_id = OLD.channel_id
       AND cnm.member_user_id = OLD.user_id;
    --
  END IF;
  --
END