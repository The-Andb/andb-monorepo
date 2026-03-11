CREATE PROCEDURE `OTE_fixCalendarDataMissingHeaders`(
    IN pTestUri VARBINARY(200)
)
BEGIN
    DECLARE pnTotalRecords INT DEFAULT 0;
    DECLARE pnFixedRecords INT DEFAULT 0;
    DECLARE pnSkippedRecords INT DEFAULT 0;
    DECLARE vId INT;
    DECLARE vCalendarData LONGTEXT;
    DECLARE vNewCalendarData LONGTEXT;
    DECLARE vBeginPos INT;
    DECLARE vAfterBeginPos INT;
    DECLARE vHasVersion TINYINT(1) DEFAULT 0;
    DECLARE done TINYINT(1) DEFAULT 0;
    
    -- CURSOR TO LOOP through records that need fixing
    -- IF pTestUri IS provided, only process that SPECIFIC URI for testing
    DECLARE cur_calendarobjects CURSOR FOR
        SELECT 
            id,
            calendardata
        FROM preflow_41.calendarobjects
        WHERE calendardata IS NOT NULL
        AND calendardata != ''
        AND LOCATE('BEGIN:VCALENDAR', calendardata) = 1
        AND (
            LOCATE('VERSION:2.0', calendardata) = 0
            OR LOCATE('CALSCALE:GREGORIAN', calendardata) = 0
            OR LOCATE('PRODID:-//Auto Team/Auto Tests CalDAV//EN-US', calendardata) = 0
        )
        AND (pTestUri IS NULL OR uri = pTestUri);
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    
    -- GET total count of records that need fixing
    SELECT COUNT(*) INTO pnTotalRecords
    FROM preflow_41.calendarobjects
    WHERE calendardata IS NOT NULL
    AND calendardata != ''
    AND LOCATE('BEGIN:VCALENDAR', calendardata) = 1
    AND (
        LOCATE('VERSION:2.0', calendardata) = 0
        OR LOCATE('CALSCALE:GREGORIAN', calendardata) = 0
        OR LOCATE('PRODID:-//Auto Team/Auto Tests CalDAV//EN-US', calendardata) = 0
    )
    AND (pTestUri IS NULL OR uri = pTestUri);
    
    -- SHOW migration info
    IF pTestUri IS NOT NULL THEN
        SELECT CONCAT('=== CALENDAR DATA FIX STARTED (TEST MODE - URI: ', HEX(pTestUri), ') ===') AS header;
    ELSE
        SELECT '=== CALENDAR DATA FIX STARTED ===' AS header;
    END IF;
    SELECT 
        pnTotalRecords AS total_records_to_fix,
        CASE 
            WHEN pTestUri IS NOT NULL THEN CONCAT('TEST MODE: Processing URI ', HEX(pTestUri))
            ELSE 'PRODUCTION MODE: Processing ALL affected records'
        END AS mode;
    
    -- OPEN CURSOR AND process records
    OPEN cur_calendarobjects;
    
    read_loop: LOOP
        FETCH cur_calendarobjects INTO vId, vCalendarData;
        
        IF done = 1 THEN
            LEAVE read_loop;
        END IF;
        
        -- CHECK IF record already has VERSION:2.0 (DOUBLE-CHECK)
        SET vHasVersion = (LOCATE('VERSION:2.0', vCalendarData) > 0);
        
        IF vHasVersion = 1 THEN
            -- Skip IF already has version (shouldn't happen due TO WHERE clause, but safety CHECK)
            SET pnSkippedRecords = pnSkippedRecords + 1;
            ITERATE read_loop;
        END IF;
        
        -- Find position after BEGIN:VCALENDAR
        SET vBeginPos = LOCATE('BEGIN:VCALENDAR', vCalendarData);
        
        IF vBeginPos = 0 THEN
            -- Should NOT happen due TO WHERE clause, but skip IF BEGIN:VCALENDAR NOT found
            SET pnSkippedRecords = pnSkippedRecords + 1;
            ITERATE read_loop;
        END IF;
        
        -- Find the position after BEGIN:VCALENDAR
        -- The correct format should be: BEGIN:VCALENDAR\n\nVERSION:2.0...
        -- After the bug, it might be: BEGIN:VCALENDAR\n\nBEGIN:VJOURNAL (OR other component)
        -- We need TO find WHERE TO INSERT the missing headers (RIGHT after BEGIN:VCALENDAR\n\n)
        SET vAfterBeginPos = vBeginPos + LENGTH('BEGIN:VCALENDAR');
        
        -- Skip any whitespace/newlines after BEGIN:VCALENDAR TO find WHERE the next content starts
        -- This handles BOTH \n\n AND \r\n\r\n formats
        WHILE vAfterBeginPos <= LENGTH(vCalendarData) 
            AND SUBSTRING(vCalendarData, vAfterBeginPos, 1) IN (CHAR(13), CHAR(10), CHAR(32), CHAR(9)) DO
            SET vAfterBeginPos = vAfterBeginPos + 1;
        END WHILE;
        
        -- Build the new calendardata WITH missing headers inserted
        -- INSERT after BEGIN:VCALENDAR WITH proper line breaks matching the original format
        -- Format: BEGIN:VCALENDAR\n\nVERSION:2.0\n\nCALSCALE:GREGORIAN\nPRODID:...\n\n[rest of content]
        SET vNewCalendarData = CONCAT(
            SUBSTRING(vCalendarData, 1, vBeginPos + LENGTH('BEGIN:VCALENDAR') - 1),
            CHAR(10), CHAR(10),
            'VERSION:2.0', CHAR(10),
            CHAR(10),
            'CALSCALE:GREGORIAN', CHAR(10),
            'PRODID:-//Auto Team/Auto Tests CalDAV//EN-US', CHAR(10),
            CHAR(10),
            SUBSTRING(vCalendarData, vAfterBeginPos)
        );
        
        -- UPDATE the record
        UPDATE preflow_41.calendarobjects
        SET calendardata = vNewCalendarData,
            size = LENGTH(vNewCalendarData),
            lastmodified = UNIX_TIMESTAMP()
        WHERE id = vId;
        
        SET pnFixedRecords = pnFixedRecords + 1;
        
        -- Log progress
        IF pTestUri IS NOT NULL THEN
            -- IN test mode, log every record
            SELECT CONCAT('Fixed record ID: ', vId, ' (URI: ', HEX(pTestUri), ')') AS progress;
        ELSE
            -- IN production mode, log every 100 records
            IF pnFixedRecords % 100 = 0 THEN
                SELECT CONCAT('Processed ', pnFixedRecords, ' records...') AS progress;
            END IF;
        END IF;
        
    END LOOP;
    
    CLOSE cur_calendarobjects;
    
    -- SHOW results
    IF pTestUri IS NOT NULL THEN
        SELECT CONCAT('=== FIX COMPLETED (TEST MODE - URI: ', HEX(pTestUri), ') ===') AS result_header;
    ELSE
        SELECT '=== FIX COMPLETED ===' AS result_header;
    END IF;
    SELECT 
        pnTotalRecords AS total_records_found,
        pnFixedRecords AS records_fixed,
        pnSkippedRecords AS records_skipped,
        CASE 
            WHEN pTestUri IS NOT NULL THEN CONCAT('TEST MODE: Processed URI ', HEX(pTestUri))
            ELSE 'PRODUCTION MODE: Processed ALL affected records'
        END AS mode,
        CASE 
            WHEN pnFixedRecords = pnTotalRecords THEN 'ALL records fixed successfully'
            ELSE CONCAT('WARNING: Expected ', pnTotalRecords, ' but fixed ', pnFixedRecords)
        END AS status;
END