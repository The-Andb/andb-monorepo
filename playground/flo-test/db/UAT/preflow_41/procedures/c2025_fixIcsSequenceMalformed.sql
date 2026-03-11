CREATE PROCEDURE `c2025_fixIcsSequenceMalformed`(
    IN psUserEmail VARCHAR(255) -- NULL = fix ALL, otherwise filter BY email (auto-prefixed WITH principals/)
)
main_block: BEGIN
    DECLARE pnUpdatedCount INT DEFAULT 0;
    DECLARE pnBatchSize INT DEFAULT 200;
    DECLARE pnMinId BIGINT DEFAULT 0;
    DECLARE pnMaxId BIGINT DEFAULT 0;
    DECLARE pnCurrentMinId BIGINT DEFAULT 0;
    DECLARE pnCurrentMaxId BIGINT DEFAULT 0;
    DECLARE pnIteration INT DEFAULT 0;
    DECLARE pnRowsAffected INT DEFAULT 0;
    DECLARE pnCalendarsUpdated INT DEFAULT 0;
    DECLARE pnChangesUpdated INT DEFAULT 0;
    DECLARE pnChangesGlobalUpdated INT DEFAULT 0;
    DECLARE psUserPrincipalUri VARCHAR(255) DEFAULT NULL;
    DECLARE pnMigrationStart INT DEFAULT 0;
    
    -- Record migration start time (used TO identify patched records later)
    SET pnMigrationStart = UNIX_TIMESTAMP();
    
    -- Auto-ADD prefix IF email provided
    IF psUserEmail IS NOT NULL THEN
        SET psUserPrincipalUri = CONCAT('principals/', psUserEmail);
    END IF;
    
    -- GET MIN/MAX id FROM calendarobjects that have malformed SEQUENCE fields
    IF psUserEmail IS NULL THEN
        SELECT MIN(id), MAX(id) INTO pnMinId, pnMaxId 
        FROM calendarobjects
        WHERE calendardata LIKE '%SEQUENCE:%'
          AND (calendardata LIKE '%0SEQUENCE:%' 
               OR calendardata LIKE '%1SEQUENCE:%' 
               OR calendardata LIKE '%2SEQUENCE:%' 
               OR calendardata LIKE '%3SEQUENCE:%' 
               OR calendardata LIKE '%4SEQUENCE:%' 
               OR calendardata LIKE '%5SEQUENCE:%' 
               OR calendardata LIKE '%6SEQUENCE:%' 
               OR calendardata LIKE '%7SEQUENCE:%' 
               OR calendardata LIKE '%8SEQUENCE:%' 
               OR calendardata LIKE '%9SEQUENCE:%');
    ELSE
        SELECT MIN(co.id), MAX(co.id) INTO pnMinId, pnMaxId
        FROM calendarobjects co
        INNER JOIN calendarinstances ci ON co.calendarid = ci.calendarid
        WHERE ci.principaluri = psUserPrincipalUri
          AND co.calendardata LIKE '%SEQUENCE:%'
          AND (co.calendardata LIKE '%0SEQUENCE:%' 
               OR co.calendardata LIKE '%1SEQUENCE:%' 
               OR co.calendardata LIKE '%2SEQUENCE:%' 
               OR co.calendardata LIKE '%3SEQUENCE:%' 
               OR co.calendardata LIKE '%4SEQUENCE:%' 
               OR co.calendardata LIKE '%5SEQUENCE:%' 
               OR co.calendardata LIKE '%6SEQUENCE:%' 
               OR co.calendardata LIKE '%7SEQUENCE:%' 
               OR co.calendardata LIKE '%8SEQUENCE:%' 
               OR co.calendardata LIKE '%9SEQUENCE:%');
    END IF;
    
    -- Handle NULL VALUES (no records found)
    SET pnMinId = IFNULL(pnMinId, 0);
    SET pnMaxId = IFNULL(pnMaxId, 0);
    SET pnCurrentMinId = pnMinId;
    
    -- SHOW migration info
    SELECT '=== FIX MALFORMED SEQUENCE FIELDS MIGRATION STARTED ===' AS header;
    SELECT 
        'Two-phase approach: 1) Fix SEQUENCE fields, 2) UPDATE synctokens' AS strategy,
        pnMinId AS min_id,
        pnMaxId AS max_id,
        pnBatchSize AS batch_size,
        IFNULL(psUserEmail, 'ALL') AS filter_email,
        FROM_UNIXTIME(pnMigrationStart) AS migration_start;
    
    -- Early EXIT IF no id RANGE TO process
    IF pnMaxId = 0 THEN
        SELECT '=== NO RECORDS TO FIX ===' AS result_header;
        SELECT 0 AS records_fixed, 0 AS calendars_synctoken_increments, 0 AS batches_processed, 'No malformed SEQUENCE fields found' AS status;
        LEAVE main_block;
    END IF;
    
    -- ========================================
    -- PHASE 1: Fix calendarobjects SEQUENCE fields (fast, no synctoken updates)
    -- ========================================
    SELECT '=== PHASE 1: Fixing malformed SEQUENCE fields IN calendarobjects ===' AS phase;
    
    WHILE pnCurrentMinId <= pnMaxId DO
        SET pnIteration = pnIteration + 1;
        SET pnCurrentMaxId = pnCurrentMinId + pnBatchSize - 1;
        
        -- Fix malformed SEQUENCE fields (synctokens updated IN Phase 2)
        CALL c2025_fixIcsSequence_updateObjects(pnCurrentMinId, pnCurrentMaxId, psUserPrincipalUri);
        SET pnRowsAffected = ROW_COUNT();
        SET pnUpdatedCount = pnUpdatedCount + pnRowsAffected;
        
        -- Progress output
        IF pnIteration MOD 10 = 0 OR pnRowsAffected > 0 THEN
            SELECT CONCAT('Batch ', pnIteration, ' (id ', pnCurrentMinId, '-', pnCurrentMaxId, '): ', pnRowsAffected, ' objects. Total: ', pnUpdatedCount) AS progress;
        END IF;
        
        SET pnCurrentMinId = pnCurrentMaxId + 1;
    END WHILE;
    
    -- ========================================
    -- PHASE 2: UPDATE synctokens (once, USING lastmodified timestamp)
    -- ========================================
    SELECT '=== PHASE 2: Updating synctokens ===' AS phase;
    
    -- UPDATE calendars.synctoken for calendars that had objects patched
    IF psUserPrincipalUri IS NULL THEN
        UPDATE calendars c
        SET c.synctoken = c.synctoken + (
            SELECT COUNT(*) FROM calendarobjects co
            WHERE co.calendarid = c.id
              AND co.lastmodified >= pnMigrationStart
        )
        WHERE EXISTS (
            SELECT 1 FROM calendarobjects co
            WHERE co.calendarid = c.id
              AND co.lastmodified >= pnMigrationStart
            LIMIT 1
        );
    ELSE
        UPDATE calendars c
        INNER JOIN calendarinstances ci ON c.id = ci.calendarid
        SET c.synctoken = c.synctoken + (
            SELECT COUNT(*) FROM calendarobjects co
            WHERE co.calendarid = c.id
              AND co.lastmodified >= pnMigrationStart
        )
        WHERE ci.principaluri = psUserPrincipalUri
        AND EXISTS (
            SELECT 1 FROM calendarobjects co
            WHERE co.calendarid = c.id
              AND co.lastmodified >= pnMigrationStart
            LIMIT 1
        );
    END IF;
    SET pnCalendarsUpdated = ROW_COUNT();
    SELECT CONCAT('Updated ', pnCalendarsUpdated, ' calendars.synctoken') AS synctoken_result;
    
    -- UPDATE calendarchanges.synctoken for patched objects (sync TO calendar.synctoken)
    IF psUserPrincipalUri IS NULL THEN
        UPDATE calendarchanges cc
        INNER JOIN calendarobjects co ON cc.calendarid = co.calendarid AND cc.uri = co.uri
        INNER JOIN calendars c ON cc.calendarid = c.id
        SET cc.synctoken = c.synctoken
        WHERE co.lastmodified >= pnMigrationStart;
    ELSE
        UPDATE calendarchanges cc
        INNER JOIN calendarobjects co ON cc.calendarid = co.calendarid AND cc.uri = co.uri
        INNER JOIN calendars c ON cc.calendarid = c.id
        INNER JOIN calendarinstances ci ON co.calendarid = ci.calendarid
        SET cc.synctoken = c.synctoken
        WHERE co.lastmodified >= pnMigrationStart
          AND ci.principaluri = psUserPrincipalUri;
    END IF;
    SET pnChangesUpdated = ROW_COUNT();
    SELECT CONCAT('Updated ', pnChangesUpdated, ' calendarchanges.synctoken') AS synctoken_result;
    
    -- UPDATE calendar_changes_global.synctoken (latest per calendarid)
    IF psUserPrincipalUri IS NULL THEN
        UPDATE calendar_changes_global ccg
        SET ccg.synctoken = ccg.synctoken + 1
        WHERE ccg.id IN (
            SELECT * FROM (
                SELECT MAX(ccg2.id)
                FROM calendar_changes_global ccg2
                WHERE EXISTS (
                    SELECT 1 FROM calendarobjects co
                    WHERE co.calendarid = ccg2.calendarid
                      AND co.lastmodified >= pnMigrationStart
                    LIMIT 1
                )
                GROUP BY ccg2.calendarid
            ) AS tmp
        );
    ELSE
        UPDATE calendar_changes_global ccg
        INNER JOIN calendarinstances ci ON ccg.calendarid = ci.calendarid
        SET ccg.synctoken = ccg.synctoken + 1
        WHERE ci.principaluri = psUserPrincipalUri
        AND ccg.id IN (
            SELECT * FROM (
                SELECT MAX(ccg2.id)
                FROM calendar_changes_global ccg2
                WHERE EXISTS (
                    SELECT 1 FROM calendarobjects co
                    WHERE co.calendarid = ccg2.calendarid
                      AND co.lastmodified >= pnMigrationStart
                    LIMIT 1
                )
                GROUP BY ccg2.calendarid
            ) AS tmp
        );
    END IF;
    SET pnChangesGlobalUpdated = ROW_COUNT();
    SELECT CONCAT('Updated ', pnChangesGlobalUpdated, ' calendar_changes_global.synctoken') AS synctoken_result;
    
    -- Final summary
    SELECT '=== MIGRATION COMPLETED ===' AS result_header;
    SELECT 
        pnUpdatedCount AS calendarobjects_fixed,
        pnCalendarsUpdated AS calendars_synctoken_updated,
        pnChangesUpdated AS calendarchanges_synctoken_updated,
        pnChangesGlobalUpdated AS calendar_changes_global_synctoken_updated,
        pnIteration AS batches_processed,
        CONCAT('Successfully fixed ', pnUpdatedCount, ' malformed SEQUENCE fields') AS status;
END