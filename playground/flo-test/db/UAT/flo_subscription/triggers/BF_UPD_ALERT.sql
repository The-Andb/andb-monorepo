CREATE TRIGGER `BF_UPD_ALERT` BEFORE UPDATE ON `alert` FOR EACH ROW BEGIN
  --
  CALL u2025_upsertUserAlertWarning(IF(NEW.deleted_at IS NULL, 1, 0), 0, new.limit_type, new.limit_at, NEW.user_id);
  --
END