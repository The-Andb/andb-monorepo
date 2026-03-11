CREATE PROCEDURE `C2025_batchInsertReachAlerts`()
BEGIN
    DECLARE pnBatchSize INT DEFAULT 2000;
    DECLARE pnTotalInserted INT DEFAULT 0;
    DECLARE pnRowsAffected INT DEFAULT 0;
    DECLARE pnIteration INT DEFAULT 0;
    DECLARE pnMinUsageId BIGINT DEFAULT 0;
    DECLARE pnMaxUsageId BIGINT DEFAULT 0;
    DECLARE pnCurrentMinId BIGINT DEFAULT 0;
    DECLARE pnCurrentMaxId BIGINT DEFAULT 0;
    
    -- GET min/max USAGE IDs for pagination
    SELECT MIN(id), MAX(id) INTO pnMinUsageId, pnMaxUsageId
    FROM usages
    WHERE is_active = 1;
    
    SET pnCurrentMinId = pnMinUsageId;
    
    -- SHOW migration info
    SELECT '=== REACH ALERTS BATCH INSERT STARTED ===' AS header;
    SELECT 
        pnMinUsageId AS min_usage_id,
        pnMaxUsageId AS max_usage_id,
        pnBatchSize AS batch_size;
    
    -- Process IN ID-based batches
    WHILE pnCurrentMinId <= pnMaxUsageId DO
        SET pnIteration = pnIteration + 1;
        SET pnCurrentMaxId = pnCurrentMinId + pnBatchSize - 1;
        
        -- INSERT batch for current ID RANGE
        INSERT INTO alert (
            user_id,
            component_id,
            limit_type,
            limit_at,
            limit_by,
            last_sent_mail,
            grace_period_mail_count,
            deleted_at
        )
        SELECT 
            u.user_id,
            u.component_id,
            'REACH' AS limit_type,
            NOW(3) AS limit_at,
            'API' AS limit_by,
            NULL AS last_sent_mail,
            0 AS grace_period_mail_count,
            NULL AS deleted_at
        FROM usages u
        INNER JOIN orders o 
            ON u.user_id = o.user_id 
            AND o.is_active = 1
        INNER JOIN order_details od 
            ON o.id = od.order_id 
            AND od.component_id = u.component_id
        INNER JOIN components c 
            ON u.component_id = c.id
        LEFT JOIN alert a 
            ON a.user_id = u.user_id 
            AND a.component_id = u.component_id 
            AND a.limit_type = 'REACH'
            AND a.deleted_at IS NULL
        WHERE u.id BETWEEN pnCurrentMinId AND pnCurrentMaxId  -- ID-based pagination
          AND u.is_active = 1
          AND c.type != 3                           -- Skip components WITH type = 3
          AND od.component_value != -1              -- Skip unlimited plans (-1 means unlimited)
          AND u.used_value >= od.component_value    -- Only WHERE USAGE REACHs LIMIT
          AND a.id IS NULL;                         -- No existing non-deleted REACH alert
        
        SET pnRowsAffected = ROW_COUNT();
        SET pnTotalInserted = pnTotalInserted + pnRowsAffected;
        
        -- Progress output (every 10 batches TO reduce output)
        IF pnIteration MOD 10 = 0 OR pnRowsAffected > 0 THEN
            SELECT CONCAT('Batch ', pnIteration, ' (ID ', pnCurrentMinId, '-', pnCurrentMaxId, '): Inserted ', pnRowsAffected, '. Total: ', pnTotalInserted) AS progress;
        END IF;
        
        -- Move TO next batch
        SET pnCurrentMinId = pnCurrentMaxId + 1;
        
    END WHILE;
    
    -- Final summary
    SELECT '=== BATCH INSERT COMPLETED ===' AS result_header;
    SELECT 
        pnTotalInserted AS alerts_inserted,
        pnIteration AS batches_processed;
    
END