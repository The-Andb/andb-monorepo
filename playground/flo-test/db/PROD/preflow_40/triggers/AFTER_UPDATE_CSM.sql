CREATE TRIGGER `AFTER_UPDATE_CSM` AFTER UPDATE ON `collection_shared_member` FOR EACH ROW BEGIN
  --
  IF OLD.shared_status <> NEW.shared_status
    OR OLD.access <> NEW.access
  THEN
    -- INSERT INTO audit_log(table_name, operation, record_id, old_data, new_data) VALUES ('collection_notification_member', 'UPDATE', NEW.id, JSON_OBJECT('OLD.shared_status', OLD.shared_status), JSON_OBJECT('NEW.shared_status', NEW.shared_status));
    --
    UPDATE collection_notification_member cnm
       SET cnm.is_active = IF(NEW.shared_status = 1, 1, 0)
          ,cnm.member_calendar_uri = IF(NEW.shared_status = 1, NEW.calendar_uri, cnm.member_calendar_uri)
          ,cnm.access = NEW.access
     WHERE cnm.collection_id = OLD.collection_id
       AND cnm.member_user_id = OLD.member_user_id;
    --
  END IF;
  --
END