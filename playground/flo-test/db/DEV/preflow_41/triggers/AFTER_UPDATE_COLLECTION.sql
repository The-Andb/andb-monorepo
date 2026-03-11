CREATE TRIGGER `AFTER_UPDATE_COLLECTION` AFTER UPDATE ON `collection` FOR EACH ROW BEGIN
  -- 
  IF (IFNULL(NEW.channel_id, 0) <> IFNULL(OLD.channel_id, 0)) THEN
    --
    UPDATE collection_notification_member cnm
       SET cnm.channel_id = NEW.channel_id
     WHERE cnm.collection_id = OLD.id;
  END IF;
  -- 
  
  -- 
  IF NEW.is_trashed <> OLD.is_trashed THEN
    --
    UPDATE collection_notification_member cnm
       SET cnm.is_active = IF(NEW.is_trashed = 0, 1, 0)
     WHERE cnm.collection_id = OLD.id;
   END IF;
  -- 
END