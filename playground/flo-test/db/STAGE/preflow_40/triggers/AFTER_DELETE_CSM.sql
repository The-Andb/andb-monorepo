CREATE TRIGGER `AFTER_DELETE_CSM` AFTER DELETE ON `collection_shared_member` FOR EACH ROW BEGIN
  --
  DELETE FROM collection_notification_member
   WHERE collection_id = OLD.collection_id
     AND member_user_id = OLD.member_user_id;
  --
END