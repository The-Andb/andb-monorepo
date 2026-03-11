CREATE TRIGGER `AFTER_DELETE_COLLECTION` AFTER DELETE ON `collection` FOR EACH ROW BEGIN
  --
  DELETE FROM collection_notification_member
   WHERE collection_id = OLD.id;
  --
END