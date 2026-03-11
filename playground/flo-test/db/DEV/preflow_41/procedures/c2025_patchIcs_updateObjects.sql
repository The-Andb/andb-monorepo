CREATE PROCEDURE `c2025_patchIcs_updateObjects`(
    IN pnMinId BIGINT,
    IN pnMaxId BIGINT,
    IN psUserPrincipalUri VARCHAR(255)
)
BEGIN
    IF psUserPrincipalUri IS NULL THEN
        -- USE derived TABLE TO CALL function ONCE per row, THEN reuse result for etag/size
        -- CONVERT TO utf8mb4 TO handle BLOB data properly WITH regex operations
        UPDATE calendarobjects co
        INNER JOIN (
            SELECT id, 
                   c2025_patchIcs_transformData(CONVERT(calendardata USING utf8mb4)) AS new_data
            FROM calendarobjects
            WHERE id BETWEEN pnMinId AND pnMaxId
              AND calendardata LIKE 'BEGIN:VCALENDAR%'
              AND (LEFT(calendardata, 80) NOT LIKE '%VERSION:%'
                   OR LEFT(calendardata, 80) NOT LIKE '%PRODID:%')
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
                   c2025_patchIcs_transformData(CONVERT(co2.calendardata USING utf8mb4)) AS new_data
            FROM calendarobjects co2
            INNER JOIN calendarinstances ci ON co2.calendarid = ci.calendarid
            WHERE co2.id BETWEEN pnMinId AND pnMaxId
              AND co2.calendardata LIKE 'BEGIN:VCALENDAR%'
              AND (LEFT(co2.calendardata, 80) NOT LIKE '%VERSION:%'
                   OR LEFT(co2.calendardata, 80) NOT LIKE '%PRODID:%')
              AND ci.principaluri = psUserPrincipalUri
        ) AS transformed ON co.id = transformed.id
        SET 
            co.calendardata = CONVERT(transformed.new_data USING BINARY),
            co.etag = MD5(transformed.new_data),
            co.`size` = LENGTH(transformed.new_data),
            co.lastmodified = UNIX_TIMESTAMP();
    END IF;
END