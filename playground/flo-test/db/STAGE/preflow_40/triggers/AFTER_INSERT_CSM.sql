CREATE TRIGGER `AFTER_INSERT_CSM` AFTER INSERT ON `collection_shared_member` FOR EACH ROW BEGIN
  --
  CALL c2025_insertCollectionNotificationMember(
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
END