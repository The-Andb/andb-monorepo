CREATE TRIGGER `BF_UPD_CARD_CONTACT` BEFORE UPDATE ON `card_contact` FOR EACH ROW BEGIN
  CALL c2025_cleanEmail4Contacts(NEW.email_address, @cleaned);
  SET NEW.email_text = @cleaned;
END