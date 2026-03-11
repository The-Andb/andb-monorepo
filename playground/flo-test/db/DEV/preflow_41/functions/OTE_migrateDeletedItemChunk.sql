CREATE FUNCTION `OTE_migrateDeletedItemChunk`() RETURNS INT
BEGIN
    DECLARE no_more_rows   BOOLEAN DEFAULT FALSE;
    DECLARE nCount         INT DEFAULT 0;
    DECLARE vID            BIGINT;
    DECLARE vUserID        BIGINT;
    DECLARE vItemID        BIGINT;
    DECLARE vItemUID       VARBINARY(1000);
    DECLARE vItemType      VARBINARY(50);
    DECLARE vIsRecovery    TINYINT UNSIGNED;
    DECLARE vCreatedDate   DOUBLE(13,3);
    DECLARE vUpdatedDate   DOUBLE(13,3);

    DECLARE usr_cursor CURSOR FOR
      -- Start of: main script
      SELECT di.id
             , di.user_id
             , di.item_id
             , di.item_uid
             , di.item_type
             , di.is_recovery
             , di.created_date
             , di.updated_date
        FROM deleted_item di
        LEFT JOIN deleted_item_partitioned dip
               ON dip.id = di.id
        WHERE di.created_sec >= 1754006400
          AND di.created_sec <  unix_timestamp()
          AND dip.id IS NULL
        ORDER BY di.id
        LIMIT 1000;
      -- END of: main script

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET no_more_rows = TRUE;

    OPEN usr_cursor;
    usr_loop: LOOP
        FETCH usr_cursor
         INTO vID, vUserID, vItemID, vItemUID, vItemType, vIsRecovery, vCreatedDate, vUpdatedDate;
        IF no_more_rows THEN
            CLOSE usr_cursor;
            LEAVE usr_loop;
        END IF;

        -- main INSERT
        INSERT INTO deleted_item_partitioned
              (id, user_id, item_id, item_uid, item_type, is_recovery, created_date, updated_date)
        VALUES(vID, vUserID, vItemID, vItemUID, vItemType, vIsRecovery, vCreatedDate, vUpdatedDate)
        ON DUPLICATE KEY UPDATE
              user_id      = VALUES(user_id)
            , item_id      = VALUES(item_id)
            , item_uid     = VALUES(item_uid)
            , item_type    = VALUES(item_type)
            , is_recovery  = VALUES(is_recovery)
            , created_date = VALUES(created_date)
            , updated_date = VALUES(updated_date)
        ;

        SET nCount = nCount + 1;
    END LOOP usr_loop;

    RETURN nCount;
END