CREATE PROCEDURE `OTE_migrateDeletedItemChunk`(IN pnUserId BIGINT)
BEGIN
    DECLARE nDone INT DEFAULT 0;

    -- Ở đây xử lý migrate dữ liệu cho user_id cụ thể
    -- Ví dụ INSERT/UPDATE qua bảng partitioned
    INSERT INTO deleted_item_partitioned (id, user_id, item_id, item_uid, item_type, is_recovery, created_date, updated_date)
    SELECT di.id, di.user_id, di.item_id, di.item_uid, di.item_type, di.is_recovery, di.created_date, di.updated_date
      FROM deleted_item di
     WHERE di.user_id = pnUserId
       AND di.created_sec >= UNIX_TIMESTAMP('2025-08-01 00:00:00')
       AND di.created_sec <  UNIX_TIMESTAMP(NOW(3))
    ON DUPLICATE KEY UPDATE
        item_uid        = VALUES(item_uid),
        item_type       = VALUES(item_type),
        is_recovery     = VALUES(is_recovery),
        updated_date    = VALUES(updated_date);

    SET nDone = ROW_COUNT();

    SELECT nDone AS migrated_rows;
END