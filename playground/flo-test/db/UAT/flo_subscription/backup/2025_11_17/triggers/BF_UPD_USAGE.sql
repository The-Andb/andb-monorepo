CREATE TRIGGER `BF_UPD_USAGE` BEFORE UPDATE ON `usages` FOR EACH ROW BEGIN
  --
  CALL u2025_upsertUserUsageWarning(NEW.used_value, OLD.component_id, OLD.user_id);
  --
END