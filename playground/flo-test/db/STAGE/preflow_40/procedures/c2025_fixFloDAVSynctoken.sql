CREATE PROCEDURE `c2025_fixFloDAVSynctoken`(
    IN psUserEmail VARCHAR(255)  -- NULL = fix ALL, otherwise filter BY email
)
BEGIN
    DECLARE pnCalendarChangesFixed INT DEFAULT 0;
    DECLARE pnCalendarChangesGlobalFixed INT DEFAULT 0;
    DECLARE pnCalendarsFixed INT DEFAULT 0;
    DECLARE psUserPrincipalUri VARCHAR(255) DEFAULT NULL;
    
    -- CURSOR variables
    DECLARE pnCurrentCalendarId INT;
    DECLARE pnCurrentSynctoken INT;
    DECLARE pnDone INT DEFAULT 0;
    DECLARE pnRowsAffected INT DEFAULT 0;
    
    -- CURSOR for affected calendars (uses EXISTS for faster lookup)
    DECLARE cur_calendars CURSOR FOR
        SELECT c.id, c.synctoken
        FROM calendars c
        WHERE (psUserPrincipalUri IS NULL OR EXISTS (
              SELECT 1 FROM calendarinstances ci 
              WHERE ci.calendarid = c.id AND ci.principaluri = psUserPrincipalUri
              LIMIT 1
          ))
          AND EXISTS (
              SELECT 1 FROM calendarobjects co
              WHERE co.calendarid = c.id
                AND LEFT(co.calendardata, 100) LIKE '%PRODID:-//FloDAV//EN%'
              LIMIT 1
          );
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET pnDone = 1;
    
    -- Auto-ADD prefix IF email provided
    IF psUserEmail IS NOT NULL THEN
        SET psUserPrincipalUri = CONCAT('principals/', psUserEmail);
    END IF;
    
    -- ========================================
    -- STEP 1: Preview affected calendars (uses EXISTS for faster lookup)
    -- ========================================
    SELECT '=== CALENDARS WITH FLODAV OBJECTS (PREVIEW) ===' AS header;
    
    IF psUserPrincipalUri IS NULL THEN
        SELECT 
            c.id AS calendar_id,
            c.synctoken AS current_synctoken,
            c.synctoken + 1 AS new_change_synctoken,
            c.synctoken + 2 AS new_calendar_synctoken
        FROM calendars c
        WHERE EXISTS (
            SELECT 1 FROM calendarobjects co
            WHERE co.calendarid = c.id
              AND LEFT(co.calendardata, 100) LIKE '%PRODID:-//FloDAV//EN%'
            LIMIT 1
        );
    ELSE
        SELECT 
            c.id AS calendar_id,
            ci.principaluri,
            ci.displayname,
            c.synctoken AS current_synctoken,
            c.synctoken + 1 AS new_change_synctoken,
            c.synctoken + 2 AS new_calendar_synctoken
        FROM calendars c
        INNER JOIN calendarinstances ci ON c.id = ci.calendarid
        WHERE ci.principaluri = psUserPrincipalUri
          AND EXISTS (
              SELECT 1 FROM calendarobjects co
              WHERE co.calendarid = c.id
                AND LEFT(co.calendardata, 100) LIKE '%PRODID:-//FloDAV//EN%'
              LIMIT 1
          );
    END IF;
    
    -- ========================================
    -- STEP 2: Process EACH calendar USING CURSOR
    -- ========================================
    SELECT '=== STEP 2: Processing calendars one BY one ===' AS phase;
    
    OPEN cur_calendars;
    
    calendar_loop: LOOP
        FETCH cur_calendars INTO pnCurrentCalendarId, pnCurrentSynctoken;
        
        IF pnDone THEN
            LEAVE calendar_loop;
        END IF;
        
        -- 2a: UPDATE calendarchanges.synctoken for this calendar
        UPDATE calendarchanges cc
        SET cc.synctoken = pnCurrentSynctoken + 1
        WHERE cc.calendarid = pnCurrentCalendarId
          AND EXISTS (
              SELECT 1 FROM calendarobjects co
              WHERE co.calendarid = cc.calendarid 
                AND co.uri = cc.uri
                AND LEFT(co.calendardata, 100) LIKE '%PRODID:-//FloDAV//EN%'
          );
        
        SET pnRowsAffected = ROW_COUNT();
        SET pnCalendarChangesFixed = pnCalendarChangesFixed + pnRowsAffected;
        
        -- 2b: UPDATE calendar_changes_global.synctoken for this calendar (latest entry only)
        UPDATE calendar_changes_global ccg
        SET ccg.synctoken = pnCurrentSynctoken + 1
        WHERE ccg.calendarid = pnCurrentCalendarId
          AND ccg.id = (
              SELECT MAX(id) FROM (
                  SELECT id FROM calendar_changes_global 
                  WHERE calendarid = pnCurrentCalendarId
              ) AS tmp
          );
        
        IF ROW_COUNT() > 0 THEN
            SET pnCalendarChangesGlobalFixed = pnCalendarChangesGlobalFixed + 1;
        END IF;
        
        -- 2c: UPDATE calendars.synctoken for this calendar
        UPDATE calendars c
        SET c.synctoken = pnCurrentSynctoken + 2
        WHERE c.id = pnCurrentCalendarId;
        
        IF ROW_COUNT() > 0 THEN
            SET pnCalendarsFixed = pnCalendarsFixed + 1;
        END IF;
        
    END LOOP;
    
    CLOSE cur_calendars;
END