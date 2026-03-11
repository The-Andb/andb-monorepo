CREATE TRIGGER `BF_INS_USAGE` BEFORE INSERT ON `usages` FOR EACH ROW BEGIN
  --
  CALL u2025_upsertUserUsageWarning(NEW.used_value, NEW.used_value, NEW.component_id, NEW.user_id);
  --
END