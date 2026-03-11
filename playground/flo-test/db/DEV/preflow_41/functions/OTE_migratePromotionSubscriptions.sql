CREATE FUNCTION `OTE_migratePromotionSubscriptions`() RETURNS INT
    READS SQL DATA
    DETERMINISTIC
BEGIN
    DECLARE nPromotionExist INT DEFAULT 0;
    DECLARE nPromotionTypeVal TINYINT;
    DECLARE vPromotionValueStr VARCHAR(100);
    DECLARE nPromotionValueNum DOUBLE(13,3);
    DECLARE nPromotionValueNum2 DOUBLE(13,3);
    DECLARE nCurrentTimestampVal DOUBLE(13,3);
    DECLARE nupdatedRows INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- RETURN -1 TO indicate error
        RETURN -1;
    END;
    
    -- Step 1: CHECK IF admin_promotion record EXISTS
    SELECT COUNT(*) INTO nPromotionExist 
    FROM admin_promotion 
    WHERE promotion_type = 2;
    
    -- IF no record EXISTS, RETURN 0
    IF nPromotionExist = 0 THEN
        RETURN 0;
    END IF;
    
    -- Step 2: GET promotion_type AND promotion_value
    SELECT promotion_type, promotion_value 
    INTO nPromotionTypeVal, vPromotionValueStr
    FROM admin_promotion 
    WHERE promotion_type = 2 
    LIMIT 1;
    
    -- Step 3: Parse JSON promotion_value TO extract start timestamp
    -- Extract the "start" value FROM JSON: {"start": 1759293353, "END": 1798761599}
    -- CONVERT VARCHAR TO JSON AND THEN parse
    SET nPromotionValueNum2 = CAST(JSON_UNQUOTE(JSON_EXTRACT(CAST(vPromotionValueStr AS JSON), '$.start')) AS DECIMAL(13,3));
    
    -- Step 4: GET promotion_value FROM promotion_type = 1 for end_date
    SELECT promotion_value INTO vPromotionValueStr
    FROM admin_promotion 
    WHERE promotion_type = 1 
    LIMIT 1;
    
    -- CONVERT promotion_value FROM promotion_type = 1 TO number
    SET nPromotionValueNum = CAST(vPromotionValueStr AS DECIMAL(13,3));
    
    -- GET current timestamp (Unix timestamp IN seconds TO MATCH promotion_value format)
    SET nCurrentTimestampVal = UNIX_TIMESTAMP(NOW());
    
    -- Validate conditions: promotion_type = 2 AND start value > now() AND BOTH VALUES exist
    IF nPromotionTypeVal = 2 AND nPromotionValueNum > nCurrentTimestampVal AND nPromotionValueNum IS NOT NULL AND nPromotionValueNum2 IS NOT NULL THEN
        
        -- Step 5: UPDATE subscription_purchase.end_date AND start_date for users IN group_user
        UPDATE subscription_purchase sp
        SET sp.start_date = nCurrentTimestampVal,
            sp.end_date = nPromotionValueNum,
            sp.updated_date = nCurrentTimestampVal
        WHERE sp.is_current = 1
            AND sp.created_date <= nPromotionValueNum2
            AND NOT EXISTS (
                SELECT 1 
                FROM OTE_user_skip_force_subscription ote 
                WHERE ote.user_id = sp.user_id
            );
        
        -- GET number of updated rows
        SET nupdatedRows = ROW_COUNT();
        
        -- RETURN number of updated rows
        RETURN nupdatedRows;
        
    ELSE
        -- Conditions NOT met, RETURN 0
        RETURN 0;
    END IF;
    
END