CREATE TRIGGER `BF_INS_ALERT` BEFORE INSERT ON `alert` FOR EACH ROW BEGIN
  --
  CALL u2025_upsertUserAlertWarning(1, 0, new.limit_type, new.limit_at, NEW.user_id);
  --
END