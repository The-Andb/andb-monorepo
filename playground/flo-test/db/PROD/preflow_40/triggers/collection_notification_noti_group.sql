CREATE TRIGGER `collection_notification_noti_group` BEFORE INSERT ON `collection_notification` FOR EACH ROW BEGIN
  -- CHECK IF object_type IS 'EMAIL'
  IF NEW.object_type IN ('EMAIL', 'GMAIL', 'EMAIL365') THEN
    SET NEW.is_email = 1;
    SET NEW.noti_group = 1;
  -- event alert
  ELSEIF (NEW.object_type = 'VEVENT' AND NEW.action = 70) THEN
  SET NEW.noti_group = 2;
  -- todo alert
  ELSEIF (NEW.object_type = 'VTODO' AND NEW.action = 19) THEN
  SET NEW.noti_group = 3;
  ELSE
    SET NEW.is_email = NULL;
    SET NEW.noti_group = NULL;
  END IF;
END