CREATE PROCEDURE `c2025_fixIcsSequence_updateObjects`(
    IN pnMinId BIGINT,
    IN pnMaxId BIGINT,
    IN psUserPrincipalUri VARCHAR(255)
)
BEGIN
    IF psUserPrincipalUri IS NULL THEN
        -- Fix malformed SEQUENCE fields: REPLACE "[0-9]{1,3}SEQUENCE:" WITH "SEQUENCE:"
        -- Pattern matches: digit(s) followed BY SEQUENCE: anywhere (NOT just at line boundaries)
        -- USE explicit IF logic TO preserve newlines correctly
        UPDATE calendarobjects
        SET 
            calendardata = REGEXP_REPLACE(
                calendardata,
                -- MATCH 1-3 digits followed BY SEQUENCE: (most SEQUENCE VALUES are 1-3 digits)
                -- USING {1,3} instead of {1,10} TO reduce backtracking AND avoid timeout
                '([0-9]{1,3})(SEQUENCE:)',
                -- Always ADD newline BEFORE SEQUENCE: (handles BOTH mid-line AND line-start cases)
                -- Note: IF already preceded BY newline, this creates DOUBLE newline which IS acceptable IN ICS
                '\nSEQUENCE:',
                1,
                0
            ),
            -- Calculate etag AND size FROM the same expression (MySQL evaluates SET USING original VALUES)
            etag = MD5(REGEXP_REPLACE(
                calendardata,
                '([0-9]{1,3})(SEQUENCE:)',
                '\nSEQUENCE:',
                1,
                0
            )),
            `size` = LENGTH(REGEXP_REPLACE(
                calendardata,
                '([0-9]{1,3})(SEQUENCE:)',
                '\nSEQUENCE:',
                1,
                0
            )),
            lastmodified = UNIX_TIMESTAMP()
        WHERE id BETWEEN pnMinId AND pnMaxId
          AND calendardata LIKE '%SEQUENCE:%'
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
        -- Same logic but filtered BY user principal URI
        -- USE explicit IF logic TO preserve newlines correctly
        UPDATE calendarobjects co
        INNER JOIN calendarinstances ci ON co.calendarid = ci.calendarid
        SET 
            co.calendardata = REGEXP_REPLACE(
                co.calendardata,
                -- MATCH 1-3 digits followed BY SEQUENCE: (most SEQUENCE VALUES are 1-3 digits)
                -- USING {1,3} instead of {1,10} TO reduce backtracking AND avoid timeout
                '([0-9]{1,3})(SEQUENCE:)',
                -- Always ADD newline BEFORE SEQUENCE: (handles BOTH mid-line AND line-start cases)
                -- Note: IF already preceded BY newline, this creates DOUBLE newline which IS acceptable IN ICS
                '\nSEQUENCE:',
                1,
                0
            ),
            -- Calculate etag AND size FROM the same expression (MySQL evaluates SET USING original VALUES)
            co.etag = MD5(REGEXP_REPLACE(
                co.calendardata,
                '([0-9]{1,3})(SEQUENCE:)',
                '\nSEQUENCE:',
                1,
                0
            )),
            co.`size` = LENGTH(REGEXP_REPLACE(
                co.calendardata,
                '([0-9]{1,3})(SEQUENCE:)',
                '\nSEQUENCE:',
                1,
                0
            )),
            co.lastmodified = UNIX_TIMESTAMP()
        WHERE co.id BETWEEN pnMinId AND pnMaxId
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
               OR co.calendardata LIKE '%9SEQUENCE:%')
          AND ci.principaluri = psUserPrincipalUri;
    END IF;
END