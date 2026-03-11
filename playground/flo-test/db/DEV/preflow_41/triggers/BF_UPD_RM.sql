CREATE TRIGGER `BF_UPD_RM` BEFORE UPDATE ON `realtime_message` FOR EACH ROW BEGIN
  --
  CALL c2025_cleanEmail4Mentions(NEW.metadata, @cleaned);
  SET NEW.mention_emails = @cleaned;
  --
END