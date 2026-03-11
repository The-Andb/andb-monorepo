CREATE PROCEDURE `OTE_updateUsagesUpdatedDate`()
BEGIN
    DECLARE pnUpdatedCount INT DEFAULT 0;
    DECLARE pnTotalActiveRecords INT DEFAULT 0;
    DECLARE pnBatchSize INT DEFAULT 500;
    DECLARE pnProcessed INT DEFAULT 0;
    DECLARE pnRowsAffected INT DEFAULT 0;
    DECLARE pnMaxId BIGINT DEFAULT 0;
    DECLARE pnCurrentId BIGINT DEFAULT 0;
    
    -- Count active records
    SELECT COUNT(*) INTO pnTotalActiveRecords
    FROM usages
    WHERE is_active = 1;
    
    -- GET max ID for batch processing
    SELECT IFNULL(MAX(id), 0) INTO pnMaxId
    FROM usages
    WHERE is_active = 1;
    
    -- SHOW info
    SELECT '=== UPDATE USAGES UPDATED_DATE STARTED ===' AS header;
    SELECT 
        pnTotalActiveRecords AS total_active_records_to_update,
        pnBatchSize AS batch_size,
        CONCAT('Processing IN batches TO avoid TRIGGER overhead (BF_UPD_USAGE)') AS note;
    
    -- Process IN batches TO avoid TRIGGER overhead
    SET pnCurrentId = 0;
    
    batch_loop: WHILE pnCurrentId < pnMaxId DO
        -- UPDATE batch BY ID RANGE
        UPDATE usages
        SET updated_date = CURRENT_TIMESTAMP(3)
        WHERE is_active = 1
          AND id > pnCurrentId
          AND id <= pnCurrentId + pnBatchSize;
        
        SET pnRowsAffected = ROW_COUNT();
        SET pnUpdatedCount = pnUpdatedCount + pnRowsAffected;
        SET pnCurrentId = pnCurrentId + pnBatchSize;
        
    END WHILE batch_loop;
    
    -- SHOW results
    SELECT '=== UPDATE COMPLETED ===' AS result_header;
    SELECT 
        pnUpdatedCount AS records_updated,
        pnTotalActiveRecords AS total_active_records,
        pnBatchSize AS batch_size_used,
        CASE 
            WHEN pnUpdatedCount = pnTotalActiveRecords THEN 'ALL active records updated successfully'
            ELSE CONCAT('WARNING: Expected ', pnTotalActiveRecords, ' but updated ', pnUpdatedCount)
        END AS status;
    
END