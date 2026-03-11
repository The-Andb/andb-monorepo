CREATE TRIGGER `BF_INS_CARD_CONTACT` BEFORE INSERT ON `card_contact` FOR EACH ROW BEGIN
  CALL c2025_cleanEmail4Contacts(NEW.email_address, @cleaned);
  SET NEW.email_text = @cleaned;
END