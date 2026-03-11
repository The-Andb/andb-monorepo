CREATE PROCEDURE `t2025_createTempTableWithValues`(
    pvTableName VARCHAR(64),  -- TABLE name TO CREATE
    pvSetValues TEXT -- Comma-separated VALUES TO INSERT
)
BEGIN
   --
   SET @SQL = CONCAT('CREATE TEMPORARY TABLE ', pvTableName, ' (tvalue VARCHAR(255) NOT NULL PRIMARY KEY)');
   -- Prepare AND execute the dynamic SQL query
   PREPARE stmt FROM @SQL;
   EXECUTE stmt;
   DEALLOCATE PREPARE stmt;
   -- IF pvSetValues IS NOT NULL, INSERT the VALUES
   IF pvSetValues IS NOT NULL THEN
     --
     SET @input = pvSetValues;
     -- LOOP through the comma-separated VALUES AND INSERT them one BY one
     WHILE LOCATE(',', @input) > 0 DO
       --
       SET @lastValue = SUBSTRING_INDEX(@input, ',', 1);  -- Extract the first value
       SET @SQL = CONCAT('INSERT INTO ', pvTableName, ' (tvalue) VALUES (\'', @lastValue, '\')');
       -- Prepare AND execute the INSERT statement
       PREPARE stmt FROM @SQL;
       EXECUTE stmt;
       DEALLOCATE PREPARE stmt;
       -- Remove the inserted value FROM the input string
       SET @input = SUBSTRING(@input, LOCATE(',', @input) + 1);
     --
     END WHILE; 
      -- INSERT the last value (after the last comma)
      SET @lastValue = @input; -- The remaining part after the last comma
      SET @SQL = CONCAT('INSERT INTO ', pvTableName, ' (tvalue) VALUES (\'', @lastValue, '\')');
      -- Prepare AND execute the INSERT for the last value
      PREPARE stmt FROM @SQL;
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt;
      --
    END IF;
  --
END