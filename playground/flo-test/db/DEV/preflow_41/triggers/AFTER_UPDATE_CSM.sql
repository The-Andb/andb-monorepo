CREATE TRIGGER `AFTER_UPDATE_CSM` AFTER UPDATE ON `collection_shared_member` FOR EACH ROW BEGIN
  --
  IF OLD.shared_status <> NEW.shared_status
    OR OLD.access <> NEW.access
  THEN
    -- INSERT INTO audit_log(table_name, operation, record_id, old_data, new_data) VALUES ('collection_notification_member', 'UPDATE', NEW.id, JSON_OBJECT('OLD.shared_status', OLD.shared_status), JSON_OBJECT('NEW.shared_status', NEW.shared_status));
    --
    CALL c2025_syncCollectionNotificationMember(
      NEW.collection_id
     ,NEW.calendar_uri
     ,NEW.access
     ,NEW.shared_email
     ,NEW.member_user_id
     ,NEW.user_id
     ,NEW.id
     ,NEW.shared_status
    );
    --
  END IF;
  --
END