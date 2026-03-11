CREATE PROCEDURE `c2025_patchIcs_updateLastModified`(
    IN pnMinId BIGINT,
    IN pnMaxId BIGINT,
    IN psUserPrincipalUri VARCHAR(255)
)
BEGIN
    DECLARE psCurrentTimestamp VARCHAR(20);
    DECLARE psLastModifiedPattern VARCHAR(50);
    DECLARE psDtstampPattern VARCHAR(50);
    
    -- Format current UTC time IN SabreDAV UTC format: YYYYMMDDTHHMMSSZ (e.g., 20251218T101352Z)
    SET psCurrentTimestamp = DATE_FORMAT(UTC_TIMESTAMP(), '%Y%m%dT%H%i%sZ');
    SET psLastModifiedPattern = CONCAT('LAST-MODIFIED:', psCurrentTimestamp);
    SET psDtstampPattern = CONCAT('DTSTAMP:', psCurrentTimestamp);
    
    IF psUserPrincipalUri IS NULL THEN
        -- USE derived TABLE TO CALL function ONCE per row, THEN reuse result for etag/size
        -- CONVERT TO utf8mb4 TO handle BLOB data properly WITH regex operations
        UPDATE calendarobjects co
        INNER JOIN (
            SELECT id, 
                   c2025_patchIcs_transformLastModified(CONVERT(calendardata USING utf8mb4), psLastModifiedPattern, psDtstampPattern) AS new_data
            FROM calendarobjects
            WHERE id BETWEEN pnMinId AND pnMaxId
              AND calendardata LIKE '%PRODID:-//FloDAV//EN%'
              AND (calendardata LIKE '%LAST-MODIFIED:%' OR calendardata LIKE '%DTSTAMP:%')
        ) AS transformed ON co.id = transformed.id
        SET 
            co.calendardata = CONVERT(transformed.new_data USING BINARY),
            co.etag = MD5(transformed.new_data),
            co.`size` = LENGTH(transformed.new_data),
            co.lastmodified = UNIX_TIMESTAMP();
    ELSE
        -- USE derived TABLE WITH user filter
        -- CONVERT TO utf8mb4 TO handle BLOB data properly WITH regex operations
        UPDATE calendarobjects co
        INNER JOIN (
            SELECT co2.id, 
                   c2025_patchIcs_transformLastModified(CONVERT(co2.calendardata USING utf8mb4), psLastModifiedPattern, psDtstampPattern) AS new_data
            FROM calendarobjects co2
            INNER JOIN calendarinstances ci ON co2.calendarid = ci.calendarid
            WHERE co2.id BETWEEN pnMinId AND pnMaxId
              AND co2.calendardata LIKE '%PRODID:-//FloDAV//EN%'
              AND (co2.calendardata LIKE '%LAST-MODIFIED:%' OR co2.calendardata LIKE '%DTSTAMP:%')
              AND ci.principaluri = psUserPrincipalUri
        ) AS transformed ON co.id = transformed.id
        SET 
            co.calendardata = CONVERT(transformed.new_data USING BINARY),
            co.etag = MD5(transformed.new_data),
            co.`size` = LENGTH(transformed.new_data),
            co.lastmodified = UNIX_TIMESTAMP();
    END IF;
END