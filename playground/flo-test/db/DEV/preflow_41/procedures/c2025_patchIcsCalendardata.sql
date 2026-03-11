CREATE PROCEDURE `c2025_patchIcsCalendardata`(
    IN psUserEmail VARCHAR(255) -- NULL = UPDATE ALL, otherwise filter BY email (auto-prefixed WITH principals/users/)
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
    
    -- GET MIN/MAX id FROM entire calendarobjects TABLE (fast query USING INDEX)
    IF psUserEmail IS NULL THEN
        SELECT MIN(id), MAX(id) INTO pnMinId, pnMaxId FROM calendarobjects;
    ELSE
        SELECT MIN(co.id), MAX(co.id) INTO pnMinId, pnMaxId
        FROM calendarobjects co
        INNER JOIN calendarinstances ci ON co.calendarid = ci.calendarid
        WHERE ci.principaluri = psUserPrincipalUri;
    END IF;
    
    -- Handle NULL VALUES (no records found)
    SET pnMinId = IFNULL(pnMinId, 0);
    SET pnMaxId = IFNULL(pnMaxId, 0);
    SET pnCurrentMinId = pnMinId;
    
    -- SHOW migration info
    SELECT '=== PATCH ICS CALENDARDATA MIGRATION STARTED ===' AS header;
    SELECT 
        'Two-phase approach: 1) Patch objects, 2) UPDATE synctokens' AS strategy,
        pnMinId AS min_id,
        pnMaxId AS max_id,
        pnBatchSize AS batch_size,
        IFNULL(psUserEmail, 'ALL') AS filter_email,
        FROM_UNIXTIME(pnMigrationStart) AS migration_start;
    
    -- Early EXIT IF no id RANGE TO process
    IF pnMaxId = 0 THEN
        SELECT '=== NO RECORDS TO UPDATE ===' AS result_header;
        SELECT 0 AS records_updated, 0 AS calendars_synctoken_increments, 0 AS batches_processed, 'No records found' AS status;
        LEAVE main_block;
    END IF;
    
    -- ========================================
    -- PHASE 1: Patch calendarobjects only (fast, no synctoken updates)
    -- ========================================
    SELECT '=== PHASE 1: Patching calendarobjects ===' AS phase;
    
    WHILE pnCurrentMinId <= pnMaxId DO
        SET pnIteration = pnIteration + 1;
        SET pnCurrentMaxId = pnCurrentMinId + pnBatchSize - 1;
        
        -- UPDATE calendarobjects only (synctokens updated IN Phase 2)
        CALL c2025_patchIcs_updateObjects(pnCurrentMinId, pnCurrentMaxId, psUserPrincipalUri);
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
        pnUpdatedCount AS calendarobjects_patched,
        pnCalendarsUpdated AS calendars_synctoken_updated,
        pnChangesUpdated AS calendarchanges_synctoken_updated,
        pnChangesGlobalUpdated AS calendar_changes_global_synctoken_updated,
        pnIteration AS batches_processed,
        CONCAT('Successfully patched ', pnUpdatedCount, ' records') AS status;
END