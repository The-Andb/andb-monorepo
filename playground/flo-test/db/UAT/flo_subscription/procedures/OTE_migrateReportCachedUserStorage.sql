CREATE PROCEDURE `OTE_migrateReportCachedUserStorage`(
    IN psUserEmail VARCHAR(255)  -- NULL = migrate ALL users, otherwise filter BY email
)
BEGIN
    DECLARE pnTotalUsers INT DEFAULT 0;
    DECLARE pnUpdatedCount INT DEFAULT 0;
    DECLARE pnBatchSize INT DEFAULT 2000;
    DECLARE pnMinUserId BIGINT DEFAULT 0;
    DECLARE pnMaxUserId BIGINT DEFAULT 0;
    DECLARE pnCurrentMinId BIGINT DEFAULT 0;
    DECLARE pnCurrentMaxId BIGINT DEFAULT 0;
    DECLARE pnIteration INT DEFAULT 0;
    DECLARE pnRowsAffected INT DEFAULT 0;
    
    -- GET total users TO UPDATE
    IF psUserEmail IS NULL THEN
        SELECT COUNT(*) INTO pnTotalUsers
        FROM preflow_41.report_cached_user rcu
        INNER JOIN flo_subscription.usages u 
            ON rcu.user_id = u.user_id
        INNER JOIN flo_subscription.components c 
            ON u.component_id = c.id
        WHERE u.is_active = 1
          AND c.type = 2;  -- STORAGE component type
        
        -- GET min/max user_id for pagination (only users WITH usages)
        SELECT MIN(rcu.user_id), MAX(rcu.user_id) INTO pnMinUserId, pnMaxUserId
        FROM preflow_41.report_cached_user rcu
        INNER JOIN flo_subscription.usages u 
            ON rcu.user_id = u.user_id
        INNER JOIN flo_subscription.components c 
            ON u.component_id = c.id
        WHERE u.is_active = 1
          AND c.type = 2;  -- STORAGE component type
    ELSE
        SELECT COUNT(*) INTO pnTotalUsers
        FROM preflow_41.report_cached_user rcu
        INNER JOIN flo_subscription.usages u 
            ON rcu.user_id = u.user_id
        INNER JOIN flo_subscription.components c 
            ON u.component_id = c.id
        WHERE u.is_active = 1
          AND c.type = 2  -- STORAGE component type
          AND rcu.email = psUserEmail;
        
        -- GET min/max user_id for pagination (filtered BY email)
        SELECT MIN(rcu.user_id), MAX(rcu.user_id) INTO pnMinUserId, pnMaxUserId
        FROM preflow_41.report_cached_user rcu
        WHERE rcu.email = psUserEmail;
    END IF;
    
    SET pnMinUserId = IFNULL(pnMinUserId, 0);
    SET pnMaxUserId = IFNULL(pnMaxUserId, 0);
    SET pnCurrentMinId = pnMinUserId;
    
    -- SHOW migration info
    SELECT '=== REPORT CACHED USER STORAGE MIGRATION STARTED ===' AS header;
    SELECT 
        pnTotalUsers AS total_users_to_update,
        pnMinUserId AS min_user_id,
        pnMaxUserId AS max_user_id,
        pnBatchSize AS batch_size,
        IFNULL(psUserEmail, 'ALL') AS filter_email;
    
    -- Early EXIT IF no records TO process
    IF pnMaxUserId = 0 OR pnTotalUsers = 0 THEN
        SELECT '=== NO RECORDS TO UPDATE ===' AS result_header;
        SELECT 0 AS records_updated, 0 AS batches_processed, 'No records found' AS status;
    ELSE
        -- Process IN ID-based batches
    WHILE pnCurrentMinId <= pnMaxUserId DO
        SET pnIteration = pnIteration + 1;
        SET pnCurrentMaxId = pnCurrentMinId + pnBatchSize - 1;
        
        -- UPDATE report_cached_user WITH storage data FROM usages
        -- storage field: JSON WITH breakdown (mail_bytes, cal_bytes, etc.)
        -- storage_total field: used_value (total bytes) - must be >= 0 for UNSIGNED
        IF psUserEmail IS NULL THEN
            UPDATE preflow_41.report_cached_user rcu
            INNER JOIN flo_subscription.usages u 
                ON rcu.user_id = u.user_id
            INNER JOIN flo_subscription.components c 
                ON u.component_id = c.id
            SET 
                rcu.storage = JSON_OBJECT(
                    'message', GREATEST(COALESCE(u.mail_bytes, 0), 0) + GREATEST(COALESCE(u.qa_bytes, 0), 0),
                    'caldav', GREATEST(COALESCE(u.cal_bytes, 0), 0),
                    'todo', GREATEST(COALESCE(u.todo_bytes, 0), 0),
                    'note', GREATEST(COALESCE(u.note_bytes, 0), 0) + GREATEST(COALESCE(u.file_note_bytes, 0), 0),
                    'event', GREATEST(COALESCE(u.event_bytes, 0), 0),
                    'comment', GREATEST(COALESCE(u.file_comment_bytes, 0), 0),
                    'chat', GREATEST(COALESCE(u.file_chat_bytes, 0), 0),
                    'contact', GREATEST(COALESCE(u.card_bytes, 0), 0),
                    'total', GREATEST(COALESCE(u.used_value, 0), 0)
                ),
                rcu.storage_total = GREATEST(COALESCE(u.used_value, 0), 0),
                rcu.updated_date = UNIX_TIMESTAMP(NOW(3))
            WHERE rcu.user_id BETWEEN pnCurrentMinId AND pnCurrentMaxId
              AND u.is_active = 1
              AND c.type = 2;  -- STORAGE component type
        ELSE
            UPDATE preflow_41.report_cached_user rcu
            INNER JOIN flo_subscription.usages u 
                ON rcu.user_id = u.user_id
            INNER JOIN flo_subscription.components c 
                ON u.component_id = c.id
            SET 
                rcu.storage = JSON_OBJECT(
                    'message', GREATEST(COALESCE(u.mail_bytes, 0), 0) + GREATEST(COALESCE(u.qa_bytes, 0), 0),
                    'caldav', GREATEST(COALESCE(u.cal_bytes, 0), 0),
                    'todo', GREATEST(COALESCE(u.todo_bytes, 0), 0),
                    'note', GREATEST(COALESCE(u.note_bytes, 0), 0) + GREATEST(COALESCE(u.file_note_bytes, 0), 0),
                    'event', GREATEST(COALESCE(u.event_bytes, 0), 0),
                    'comment', GREATEST(COALESCE(u.file_comment_bytes, 0), 0),
                    'chat', GREATEST(COALESCE(u.file_chat_bytes, 0), 0),
                    'contact', GREATEST(COALESCE(u.card_bytes, 0), 0),
                    'total', GREATEST(COALESCE(u.used_value, 0), 0)
                ),
                rcu.storage_total = GREATEST(COALESCE(u.used_value, 0), 0),
                rcu.updated_date = UNIX_TIMESTAMP(NOW(3))
            WHERE rcu.user_id BETWEEN pnCurrentMinId AND pnCurrentMaxId
              AND rcu.email = psUserEmail
              AND u.is_active = 1
              AND c.type = 2;  -- STORAGE component type
        END IF;
        
        SET pnRowsAffected = ROW_COUNT();
        SET pnUpdatedCount = pnUpdatedCount + pnRowsAffected;
        
        -- Progress output (every 10 batches OR WHEN rows affected)
        IF pnIteration MOD 10 = 0 OR pnRowsAffected > 0 THEN
            SELECT CONCAT('Batch ', pnIteration, ' (user_id ', pnCurrentMinId, '-', pnCurrentMaxId, '): Updated ', pnRowsAffected, '. Total: ', pnUpdatedCount) AS progress;
        END IF;
        
        -- Move TO next batch
        SET pnCurrentMinId = pnCurrentMaxId + 1;
        
    END WHILE;
    
    -- Final summary
    SELECT '=== MIGRATION COMPLETED ===' AS result_header;
    SELECT 
        pnUpdatedCount AS records_updated,
        pnIteration AS batches_processed,
        CASE 
            WHEN pnUpdatedCount = pnTotalUsers THEN 'ALL records updated successfully'
            ELSE CONCAT('Updated ', pnUpdatedCount, ' of ', pnTotalUsers, ' records')
        END AS status;
    END IF;
    
END