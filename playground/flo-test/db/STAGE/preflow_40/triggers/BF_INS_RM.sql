CREATE TRIGGER `BF_INS_RM` BEFORE INSERT ON `realtime_message` FOR EACH ROW BEGIN
  --
  CALL c2025_cleanEmail4Mentions(NEW.metadata, @cleaned);
  SET NEW.mention_emails = @cleaned;
  --
END