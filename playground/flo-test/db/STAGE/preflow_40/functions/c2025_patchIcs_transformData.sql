CREATE FUNCTION `c2025_patchIcs_transformData`(
    pCalendardata LONGTEXT CHARACTER SET utf8mb4
) RETURNS LONGTEXT CHARSET utf8mb4
    READS SQL DATA
    DETERMINISTIC
BEGIN
    DECLARE vHasVersion BOOLEAN;
    DECLARE vHasProdid BOOLEAN;
    DECLARE vFirstLine LONGTEXT CHARACTER SET utf8mb4;
    DECLARE vRestData LONGTEXT CHARACTER SET utf8mb4;
    DECLARE vInsertStr LONGTEXT CHARACTER SET utf8mb4 DEFAULT '';
    DECLARE vNormalizedData LONGTEXT CHARACTER SET utf8mb4;
    
    -- Normalize line endings TO CRLF (RFC 5545 compliant)
    -- Step 1: \r\n -> \n (unify TO LF)
    -- Step 2: \n -> \r\n (CONVERT ALL TO CRLF)
    SET vNormalizedData = REPLACE(REPLACE(pCalendardata, _utf8mb4'\r\n', _utf8mb4'\n'), _utf8mb4'\n', _utf8mb4'\r\n');
    
    -- CHECK IF VERSION AND PRODID exist (CHECK first 80 chars for header fields)
    SET vHasVersion = LEFT(vNormalizedData, 80) LIKE _utf8mb4'%VERSION:%';
    SET vHasProdid = LEFT(vNormalizedData, 80) LIKE _utf8mb4'%PRODID:%';
    
    -- IF BOTH exist, RETURN AS-IS
    IF vHasVersion AND vHasProdid THEN
        RETURN vNormalizedData;
    END IF;
    
    -- ADD VERSION AND/OR PRODID IF missing (split ON CRLF)
    SET vFirstLine = SUBSTRING_INDEX(vNormalizedData, _utf8mb4'\r\n', 1);
    SET vRestData = SUBSTRING(vNormalizedData, LOCATE(_utf8mb4'\r\n', vNormalizedData) + 2);
    
    -- Build INSERT string based ON what's missing (USING CRLF)
    IF NOT vHasVersion THEN
        SET vInsertStr = CONCAT(vInsertStr, _utf8mb4'\r\nVERSION:2.0');
    END IF;
    IF NOT vHasProdid THEN
        SET vInsertStr = CONCAT(vInsertStr, _utf8mb4'\r\nPRODID:-//FloDAV//EN');
    END IF;
    
    RETURN CONCAT(vFirstLine, vInsertStr, _utf8mb4'\r\n', vRestData);
END