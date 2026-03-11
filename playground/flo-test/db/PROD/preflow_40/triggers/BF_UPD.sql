CREATE TRIGGER `BF_UPD` BEFORE UPDATE ON `realtime_message` FOR EACH ROW BEGIN
  --
  IF ifnull(NEW.metadata,'') <> '' THEN 
    -- 
    SET NEW.mention_emails = (
      SELECT GROUP_CONCAT(JSON_UNQUOTE(j.email))
      FROM JSON_TABLE(
        NEW.metadata, '$.mentions[*]'
        COLUMNS (email VARCHAR(255) PATH '$.email')
      ) AS j
    );
    --
  END IF;
  --
END