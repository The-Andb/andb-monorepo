CREATE PROCEDURE `t2025_dropTempTable`(pvTableName VARCHAR(64))
BEGIN
  --
  SET @SQL = CONCAT('DROP TEMPORARY TABLE ', pvTableName);
   -- Prepare AND execute the dynamic SQL query
   PREPARE stmt FROM @SQL;
   EXECUTE stmt;
   DEALLOCATE PREPARE stmt;
  --
END