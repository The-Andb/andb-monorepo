CREATE PROCEDURE `u2026_migrateFileCountToUsages`(
    IN pnUserId BIGINT  -- NULL = migrate ALL users, otherwise filter BY SPECIFIC user_id
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
    
    -- GET total users that have file data (FROM app_account_token)
    IF pnUserId IS NULL THEN
        SELECT COUNT(DISTINCT aat.user_id) INTO pnTotalUsers
        FROM flo_subscription.app_account_token aat
        INNER JOIN preflow_41.file f ON f.user_id = aat.user_id
        WHERE CONVERT(f.object_type USING utf8mb4) = 'VJOURNAL' COLLATE utf8mb4_general_ci;
        
        -- GET min/max user_id FROM usages for pagination (only users WITH file data)
        SELECT MIN(u.user_id), MAX(u.user_id) INTO pnMinUserId, pnMaxUserId
        FROM flo_subscription.usages u
        INNER JOIN flo_subscription.app_account_token aat ON aat.user_id = u.user_id
        INNER JOIN preflow_41.file f ON f.user_id = aat.user_id
        WHERE u.is_active = 1
          AND CONVERT(f.object_type USING utf8mb4) = 'VJOURNAL' COLLATE utf8mb4_general_ci;
    ELSE
        SELECT COUNT(DISTINCT aat.user_id) INTO pnTotalUsers
        FROM flo_subscription.app_account_token aat
        INNER JOIN preflow_41.file f ON f.user_id = aat.user_id
        WHERE aat.user_id = pnUserId
          AND CONVERT(f.object_type USING utf8mb4) = 'VJOURNAL' COLLATE utf8mb4_general_ci;
        
        -- GET min/max user_id FROM usages for pagination (filtered BY user_id)
        SELECT MIN(u.user_id), MAX(u.user_id) INTO pnMinUserId, pnMaxUserId
        FROM flo_subscription.usages u
        INNER JOIN flo_subscription.app_account_token aat ON aat.user_id = u.user_id
        WHERE u.is_active = 1
          AND aat.user_id = pnUserId;
    END IF;
    
    SET pnMinUserId = IFNULL(pnMinUserId, 0);
    SET pnMaxUserId = IFNULL(pnMaxUserId, 0);
    SET pnCurrentMinId = pnMinUserId;
    
    -- SHOW migration info
    SELECT '=== FILE COUNT TO USAGES MIGRATION V2 STARTED ===' AS header;
    SELECT 
        pnTotalUsers AS total_users_with_files,
        pnMinUserId AS min_user_id,
        pnMaxUserId AS max_user_id,
        pnBatchSize AS batch_size,
        IFNULL(pnUserId, 'ALL') AS filter_user_id;
    
    -- Early EXIT IF no records TO process
    IF pnMaxUserId = 0 OR pnTotalUsers = 0 THEN
        SELECT '=== NO RECORDS TO UPDATE ===' AS result_header;
        SELECT 0 AS records_updated, 0 AS batches_processed, 'No records found' AS status;
    ELSE
        -- Process IN ID-based batches
    WHILE pnCurrentMinId <= pnMaxUserId DO
        SET pnIteration = pnIteration + 1;
        SET pnCurrentMaxId = pnCurrentMinId + pnBatchSize - 1;
        
        -- UPDATE usages WITH file counts AND bytes FROM preflow_41.file
        IF pnUserId IS NULL THEN
            UPDATE flo_subscription.usages u
            INNER JOIN flo_subscription.components c ON u.component_id = c.id
            LEFT JOIN (
                -- File note count: Count ALL VJOURNAL files BY user
                SELECT 
                    f.user_id,
                    COUNT(DISTINCT f.id) AS vjournal_count
                FROM preflow_41.file f
                WHERE f.user_id BETWEEN pnCurrentMinId AND pnCurrentMaxId
                  AND CONVERT(f.object_type USING utf8mb4) = 'VJOURNAL' COLLATE utf8mb4_general_ci
                GROUP BY f.user_id
            ) note_count ON note_count.user_id = u.user_id
            LEFT JOIN (
                -- File note bytes: Sum file sizes for VJOURNAL files BY user
                SELECT 
                    f.user_id,
                    COALESCE(SUM(f.size), 0) AS vjournal_bytes
                FROM preflow_41.file f
                WHERE f.user_id BETWEEN pnCurrentMinId AND pnCurrentMaxId
                  AND CONVERT(f.object_type USING utf8mb4) = 'VJOURNAL' COLLATE utf8mb4_general_ci
                GROUP BY f.user_id
            ) note_bytes ON note_bytes.user_id = u.user_id
            LEFT JOIN (
                -- File comment count AND bytes: Count files AND sum sizes for collections owned BY user
                SELECT 
                    c.user_id,
                    COUNT(DISTINCT sflc.file_uid) AS comment_count,
                    COALESCE(SUM(sf.size), 0) AS comment_bytes
                FROM preflow_41.storage_file_linked_collection sflc
                INNER JOIN preflow_41.storage_file sf ON CAST(sflc.file_uid AS CHAR CHARACTER SET utf8mb4) COLLATE utf8mb4_general_ci = sf.uid
                INNER JOIN preflow_41.collection c ON c.id = sflc.collection_id
                WHERE c.user_id BETWEEN pnCurrentMinId AND pnCurrentMaxId
                  AND c.user_id IS NOT NULL
                GROUP BY c.user_id
            ) comment_files ON comment_files.user_id = u.user_id
            SET 
                u.file_note_count = COALESCE(note_count.vjournal_count, 0),
                u.file_note_bytes = COALESCE(note_bytes.vjournal_bytes, 0),
                u.file_comment_count = COALESCE(comment_files.comment_count, 0),
                u.file_comment_bytes = COALESCE(comment_files.comment_bytes, 0),
                u.updated_date = NOW(3)
            WHERE u.user_id BETWEEN pnCurrentMinId AND pnCurrentMaxId
              AND u.is_active = 1
              AND c.type = 2;
        ELSE
            UPDATE flo_subscription.usages u
            INNER JOIN flo_subscription.components c ON u.component_id = c.id
            LEFT JOIN (
                -- File note count: Count ALL VJOURNAL files BY user
                SELECT 
                    f.user_id,
                    COUNT(DISTINCT f.id) AS vjournal_count
                FROM preflow_41.file f
                WHERE f.user_id = pnUserId
                  AND CONVERT(f.object_type USING utf8mb4) = 'VJOURNAL' COLLATE utf8mb4_general_ci
                GROUP BY f.user_id
            ) note_count ON note_count.user_id = u.user_id
            LEFT JOIN (
                -- File note bytes: Sum file sizes for VJOURNAL files BY user
                SELECT 
                    f.user_id,
                    COALESCE(SUM(f.size), 0) AS vjournal_bytes
                FROM preflow_41.file f
                WHERE f.user_id = pnUserId
                  AND CONVERT(f.object_type USING utf8mb4) = 'VJOURNAL' COLLATE utf8mb4_general_ci
                GROUP BY f.user_id
            ) note_bytes ON note_bytes.user_id = u.user_id
            LEFT JOIN (
                -- File comment count AND bytes: Count files AND sum sizes for collections owned BY user
                SELECT 
                    c.user_id,
                    COUNT(DISTINCT sflc.file_uid) AS comment_count,
                    COALESCE(SUM(sf.size), 0) AS comment_bytes
                FROM preflow_41.storage_file_linked_collection sflc
                INNER JOIN preflow_41.storage_file sf ON CAST(sflc.file_uid AS CHAR CHARACTER SET utf8mb4) COLLATE utf8mb4_general_ci = sf.uid
                INNER JOIN preflow_41.collection c ON c.id = sflc.collection_id
                WHERE c.user_id = pnUserId
                  AND c.user_id IS NOT NULL
                GROUP BY c.user_id
            ) comment_files ON comment_files.user_id = u.user_id
            SET 
                u.file_note_count = COALESCE(note_count.vjournal_count, 0),
                u.file_note_bytes = COALESCE(note_bytes.vjournal_bytes, 0),
                u.file_comment_count = COALESCE(comment_files.comment_count, 0),
                u.file_comment_bytes = COALESCE(comment_files.comment_bytes, 0),
                u.updated_date = NOW(3)
            WHERE u.user_id = pnUserId
              AND u.is_active = 1
              AND c.type = 2;
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
            WHEN pnUpdatedCount > 0 THEN CONCAT('Updated ', pnUpdatedCount, ' USAGE records WITH file counts')
            ELSE 'No records updated'
        END AS status;
    END IF;
    
END