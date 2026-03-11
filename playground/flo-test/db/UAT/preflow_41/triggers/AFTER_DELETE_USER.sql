CREATE TRIGGER `AFTER_DELETE_USER` AFTER DELETE ON `user` FOR EACH ROW BEGIN
  --
  DELETE FROM collection_notification_member
   WHERE member_user_id = OLD.id;
  --
END