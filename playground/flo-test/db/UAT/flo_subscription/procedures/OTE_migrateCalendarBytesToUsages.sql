CREATE PROCEDURE `OTE_migrateCalendarBytesToUsages`(
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
    
    -- GET total users that have calendar data (AS owner)
    IF psUserEmail IS NULL THEN
        SELECT COUNT(DISTINCT usr.id) INTO pnTotalUsers
        FROM preflow_41.user usr
        INNER JOIN preflow_41.calendarinstances ci 
            ON ci.principaluri = CONCAT('principals/', usr.email)
            AND ci.access = 1  -- owner only
        INNER JOIN preflow_41.calendarobjects co 
            ON co.calendarid = ci.calendarid;
        
        -- GET min/max user_id FROM usages for pagination (only users WITH calendar data)
        SELECT MIN(u.user_id), MAX(u.user_id) INTO pnMinUserId, pnMaxUserId
        FROM flo_subscription.usages u
        INNER JOIN preflow_41.user usr ON usr.id = u.user_id
        INNER JOIN preflow_41.calendarinstances ci 
            ON ci.principaluri = CONCAT('principals/', usr.email)
            AND ci.access = 1  -- owner only
        INNER JOIN preflow_41.calendarobjects co 
            ON co.calendarid = ci.calendarid
        WHERE u.is_active = 1;
    ELSE
        SELECT COUNT(DISTINCT usr.id) INTO pnTotalUsers
        FROM preflow_41.user usr
        INNER JOIN preflow_41.calendarinstances ci 
            ON ci.principaluri = CONCAT('principals/', usr.email)
            AND ci.access = 1  -- owner only
        INNER JOIN preflow_41.calendarobjects co 
            ON co.calendarid = ci.calendarid
        WHERE usr.email = psUserEmail;
        
        -- GET min/max user_id FROM usages for pagination (filtered BY email)
        SELECT MIN(u.user_id), MAX(u.user_id) INTO pnMinUserId, pnMaxUserId
        FROM flo_subscription.usages u
        INNER JOIN preflow_41.user usr ON usr.id = u.user_id
        WHERE u.is_active = 1
          AND usr.email = psUserEmail;
    END IF;
    
    SET pnMinUserId = IFNULL(pnMinUserId, 0);
    SET pnMaxUserId = IFNULL(pnMaxUserId, 0);
    SET pnCurrentMinId = pnMinUserId;
    
    -- SHOW migration info
    SELECT '=== CALENDAR BYTES TO USAGES MIGRATION V2 STARTED ===' AS header;
    SELECT 
        pnTotalUsers AS total_users_with_calendar,
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
        
        -- UPDATE usages WITH calendar bytes FROM calendarobjects
        -- JOIN via principaluri = 'principals/{email}' AND access = 1 (owner)
        IF psUserEmail IS NULL THEN
            UPDATE flo_subscription.usages u
            INNER JOIN (
                SELECT 
                    usr.id AS user_id,
                    COALESCE(SUM(CASE WHEN CONVERT(co.componenttype USING utf8mb4) = 'VEVENT' THEN co.size ELSE 0 END), 0) AS vevent_size,
                    COALESCE(SUM(CASE WHEN CONVERT(co.componenttype USING utf8mb4) = 'VJOURNAL' THEN co.size ELSE 0 END), 0) AS vjournal_size,
                    COALESCE(SUM(CASE WHEN CONVERT(co.componenttype USING utf8mb4) = 'VTODO' THEN co.size ELSE 0 END), 0) AS vtodo_size
                FROM preflow_41.user usr
                INNER JOIN preflow_41.calendarinstances ci 
                    ON ci.principaluri = CONCAT('principals/', usr.email)
                    AND ci.access = 1  -- owner only
                INNER JOIN preflow_41.calendarobjects co 
                    ON co.calendarid = ci.calendarid
                WHERE usr.id BETWEEN pnCurrentMinId AND pnCurrentMaxId
                GROUP BY usr.id
            ) cal_data ON u.user_id = cal_data.user_id
            INNER JOIN flo_subscription.components c ON u.component_id = c.id
            SET 
                u.event_bytes = cal_data.vevent_size,
                u.note_bytes = cal_data.vjournal_size,
                u.todo_bytes = cal_data.vtodo_size,
                u.cal_bytes = cal_data.vevent_size + cal_data.vjournal_size + cal_data.vtodo_size,
                u.used_value = (cal_data.vevent_size + cal_data.vjournal_size + cal_data.vtodo_size) 
                             + u.card_bytes + u.file_comment_bytes + u.file_chat_bytes 
                             + u.file_note_bytes + u.mail_bytes + u.file_contact_bytes + u.qa_bytes,
                u.updated_date = NOW(3)
            WHERE u.user_id BETWEEN pnCurrentMinId AND pnCurrentMaxId
              AND u.is_active = 1
              AND c.type = 2;  -- STORAGE component type
        ELSE
            UPDATE flo_subscription.usages u
            INNER JOIN (
                SELECT 
                    usr.id AS user_id,
                    COALESCE(SUM(CASE WHEN CONVERT(co.componenttype USING utf8mb4) = 'VEVENT' THEN co.size ELSE 0 END), 0) AS vevent_size,
                    COALESCE(SUM(CASE WHEN CONVERT(co.componenttype USING utf8mb4) = 'VJOURNAL' THEN co.size ELSE 0 END), 0) AS vjournal_size,
                    COALESCE(SUM(CASE WHEN CONVERT(co.componenttype USING utf8mb4) = 'VTODO' THEN co.size ELSE 0 END), 0) AS vtodo_size
                FROM preflow_41.user usr
                INNER JOIN preflow_41.calendarinstances ci 
                    ON ci.principaluri = CONCAT('principals/', usr.email)
                    AND ci.access = 1  -- owner only
                INNER JOIN preflow_41.calendarobjects co 
                    ON co.calendarid = ci.calendarid
                WHERE usr.id BETWEEN pnCurrentMinId AND pnCurrentMaxId
                  AND usr.email = psUserEmail
                GROUP BY usr.id
            ) cal_data ON u.user_id = cal_data.user_id
            INNER JOIN flo_subscription.components c ON u.component_id = c.id
            SET 
                u.event_bytes = cal_data.vevent_size,
                u.note_bytes = cal_data.vjournal_size,
                u.todo_bytes = cal_data.vtodo_size,
                u.cal_bytes = cal_data.vevent_size + cal_data.vjournal_size + cal_data.vtodo_size,
                u.used_value = (cal_data.vevent_size + cal_data.vjournal_size + cal_data.vtodo_size) 
                             + u.card_bytes + u.file_comment_bytes + u.file_chat_bytes 
                             + u.file_note_bytes + u.mail_bytes + u.file_contact_bytes + u.qa_bytes,
                u.updated_date = NOW(3)
            WHERE u.user_id BETWEEN pnCurrentMinId AND pnCurrentMaxId
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
            WHEN pnUpdatedCount > 0 THEN CONCAT('Updated ', pnUpdatedCount, ' USAGE records WITH calendar bytes')
            ELSE 'No records updated'
        END AS status;
    END IF;
    
END