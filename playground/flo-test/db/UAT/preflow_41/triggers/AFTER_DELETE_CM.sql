CREATE TRIGGER `AFTER_DELETE_CM` AFTER DELETE ON `conference_member` FOR EACH ROW BEGIN
  --
  DELETE FROM collection_notification_member cnm
   WHERE cnm.channel_id = OLD.channel_id
     AND cnm.member_user_id = OLD.user_id
     AND cnm.collection_id = 0;
  --
END