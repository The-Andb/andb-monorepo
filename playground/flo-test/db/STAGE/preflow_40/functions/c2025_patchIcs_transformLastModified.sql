CREATE FUNCTION `c2025_patchIcs_transformLastModified`(
    pCalendardata LONGTEXT CHARACTER SET utf8mb4,
    psLastModifiedPattern VARCHAR(50) CHARACTER SET utf8mb4,
    psDtstampPattern VARCHAR(50) CHARACTER SET utf8mb4
) RETURNS LONGTEXT CHARSET utf8mb4
    READS SQL DATA
    DETERMINISTIC
BEGIN
    DECLARE vResult LONGTEXT CHARACTER SET utf8mb4;
    DECLARE vHasLastModified BOOLEAN;
    DECLARE vHasDtstamp BOOLEAN;
    DECLARE vHasSequence BOOLEAN;
    DECLARE vHasMalformedSequence BOOLEAN;
    DECLARE vNormalizedData LONGTEXT CHARACTER SET utf8mb4;
    DECLARE vSequenceValue INT DEFAULT 0;
    DECLARE vNewSequence INT DEFAULT 1;
    
    -- Normalize line endings: CONVERT \r\n (Windows) TO \n (Unix)
    -- Note: pCalendardata IS already LONGTEXT CHARACTER SET utf8mb4
    SET vNormalizedData = REPLACE(pCalendardata, _utf8mb4'\r\n', _utf8mb4'\n');
    
    -- CHECK conditions (USING normalized data) - CHECK DTSTAMP AND LAST-MODIFIED independently
    SET vHasLastModified = vNormalizedData LIKE _utf8mb4'%LAST-MODIFIED:%';
    SET vHasDtstamp = vNormalizedData LIKE _utf8mb4'%DTSTAMP:%';
    SET vHasSequence = vNormalizedData REGEXP _utf8mb4'(^|\\n)SEQUENCE:[0-9]+(\\n|$)';
    SET vHasMalformedSequence = vNormalizedData REGEXP _utf8mb4'[0-9]{1,3}SEQUENCE:';
    
    -- Extract current SEQUENCE value IF EXISTS (for incrementing)
    IF vHasSequence OR vHasMalformedSequence THEN
        SET vSequenceValue = CAST(SUBSTRING_INDEX(REGEXP_SUBSTR(vNormalizedData, _utf8mb4'SEQUENCE:[0-9]+'), _utf8mb4':', -1) AS UNSIGNED);
        SET vNewSequence = vSequenceValue + 1;
    END IF;
    
    SET vResult = vNormalizedData;
    
    -- Step 1: UPDATE LAST-MODIFIED IF it EXISTS (independently)
    -- Z IS optional TO handle malformed timestamps without UTC indicator
    IF vHasLastModified THEN
        SET vResult = REGEXP_REPLACE(
            vResult,
            _utf8mb4'LAST-MODIFIED:[0-9]{8}T[0-9]{6}Z?',
            psLastModifiedPattern,
            1,
            0
        );
    END IF;
    
    -- Step 2: UPDATE DTSTAMP IF it EXISTS (independently)
    -- Z IS optional TO handle malformed timestamps without UTC indicator
    IF vHasDtstamp THEN
        SET vResult = REGEXP_REPLACE(
            vResult,
            _utf8mb4'DTSTAMP:[0-9]{8}T[0-9]{6}Z?',
            psDtstampPattern,
            1,
            0
        );
    END IF;
    
    -- Step 3: Increment SEQUENCE BY 1 IF it EXISTS
    IF vHasMalformedSequence THEN
        -- Fix malformed SEQUENCE AND increment BY 1
        SET vResult = REGEXP_REPLACE(
            vResult,
            _utf8mb4'([0-9]{1,3})(SEQUENCE:)([0-9]+)',
            CONCAT(_utf8mb4'\nSEQUENCE:', vNewSequence),
            1,
            0
        );
    ELSEIF vHasSequence THEN
        -- Increment properly formatted SEQUENCE BY 1
        SET vResult = REGEXP_REPLACE(
            vResult,
            _utf8mb4'(^|\\n)SEQUENCE:([0-9]+)(\\n|$)',
            CONCAT(_utf8mb4'\nSEQUENCE:', vNewSequence, _utf8mb4'\n'),
            1,
            0
        );
    END IF;
    
    RETURN vResult;
END