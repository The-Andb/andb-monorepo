CREATE FUNCTION `r2024_patchCollectionRealtimeMember`(pnCollectionId BIGINT(20)) RETURNS INT
BEGIN
    DECLARE no_more_rows    boolean;
    DECLARE nCount          INT DEFAULT 0;
    DECLARE nReturn         INT DEFAULT 0;
    DECLARE nID             BIGINT(20);
    DECLARE vName           VARCHAR(200);
    DECLARE nRole           TINYINT(1);
    DECLARE vEmail          VARCHAR(200);
    DECLARE nRevokeTime     DOUBLE(13,3);
    DECLARE usr_cursor CURSOR FOR
    # Start of: main script;
    -- owner
  SELECT u.email, rc.id, rc.name, 0
      FROM collection co
      JOIN user u ON (u.id = co.user_id)
      JOIN realtime_channel rc ON (co.id = rc.internal_channel_id)
 LEFT JOIN realtime_channel_member rcm ON (u.email = rcm.email AND rc.id = rcm.channel_id)
     WHERE rc.type = 'COLLECTION'
       AND rc.internal_channel_id = pnCollectionId
       AND rcm.id IS NULL
       AND co.type = 3
        UNION
   -- member
    SELECT csm.shared_email, rc.id, rc.name, csm.access
      FROM collection_shared_member csm
      JOIN realtime_channel rc ON (csm.collection_id = rc.internal_channel_id)
 LEFT JOIN realtime_channel_member rcm ON (csm.shared_email = rcm.email AND rc.id = rcm.channel_id)
     WHERE rc.type = 'COLLECTION'
       AND rc.internal_channel_id = pnCollectionId
       AND rcm.id IS NULL
       AND csm.shared_status = 1 -- joined only
      ;
       -- LIMIT 10000
    # END of: main script
   DECLARE CONTINUE handler FOR NOT found SET no_more_rows = TRUE;
   --
   OPEN usr_cursor;
   usr_loop: LOOP
     -- start LOOP usr_cursor
     FETCH usr_cursor 
      INTO vEmail, nID, vName, nRole;
     -- stop LOOP WHEN no_more_rows
     IF (no_more_rows) THEN
       CLOSE usr_cursor;
       LEAVE usr_loop;
     END IF;
     # main UPDATE
     INSERT INTO `realtime_channel_member`
    (`email`, `channel_id`,  `channel_name`, `role`, `created_date`, `updated_date`)
    VALUES
    (vEmail, nID, vName, nRole, unix_timestamp(now(3)), unix_timestamp(now(3)))
     ON DUPLICATE KEY UPDATE updated_date=VALUES(updated_date);
     --
     SET nCount = nCount + 1;
      # main UPDATE
     --
   END LOOP usr_loop;
   --
    UPDATE realtime_channel rc
      SET rc.patch_time = IF(nCount = 0, -unix_timestamp(now(3)), unix_timestamp(now(3)))
    WHERE rc.internal_channel_id = pnCollectionId
      AND rc.`type` = 'COLLECTION';
   --
RETURN nCount;
END