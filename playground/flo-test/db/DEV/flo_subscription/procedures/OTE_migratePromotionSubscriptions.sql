CREATE PROCEDURE `OTE_migratePromotionSubscriptions`()
BEGIN
    DECLARE pnPromotionExist INT DEFAULT 0;
    DECLARE pnPromotionTypeVal TINYINT;
    DECLARE pvPromotionValueStr VARCHAR(100);
    DECLARE pdPromotionValueNum DOUBLE(13,3);
    DECLARE pdPromotionValueNum2 DOUBLE(13,3);
    DECLARE pdCurrentTimestampVal DOUBLE(13,3);
    DECLARE pnUpdatedRows INT DEFAULT 0;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Error occurred, PROCEDURE will EXIT
        ROLLBACK;
    END;
    
    -- Start transaction
    START TRANSACTION;
    
    -- Step 1: CHECK IF admin_promotion record EXISTS
    SELECT COUNT(*) INTO pnPromotionExist 
    FROM preflow_41.admin_promotion 
    WHERE promotion_type = 2;
    
    -- IF no record EXISTS, EXIT
    IF pnPromotionExist = 0 THEN
        SELECT 'No promotion records found' AS result;
    ELSE
        -- Step 2: GET promotion_type AND promotion_value
        SELECT promotion_type, promotion_value 
        INTO pnPromotionTypeVal, pvPromotionValueStr
        FROM preflow_41.admin_promotion 
        WHERE promotion_type = 2 
        LIMIT 1;
        
        -- Step 3: Parse JSON promotion_value TO extract start timestamp
        -- Extract the "start" value FROM JSON: {"start": 1759293353, "END": 1798761599}
        -- CONVERT VARCHAR TO JSON AND THEN parse
        SET pdPromotionValueNum2 = CAST(JSON_UNQUOTE(JSON_EXTRACT(CAST(pvPromotionValueStr AS JSON), '$.start')) AS DECIMAL(13,3));
        
        -- Step 4: GET promotion_value FROM promotion_type = 1 for end_date
        SELECT promotion_value INTO pvPromotionValueStr
        FROM preflow_41.admin_promotion 
        WHERE promotion_type = 1 
        LIMIT 1;
        
        -- CONVERT promotion_value FROM promotion_type = 1 TO number
        SET pdPromotionValueNum = CAST(pvPromotionValueStr AS DECIMAL(13,3));
        
        -- GET current timestamp (Unix timestamp IN seconds TO MATCH promotion_value format)
        SET pdCurrentTimestampVal = UNIX_TIMESTAMP(NOW());
        
        
        -- Validate conditions: promotion_type = 2 AND start value > now() AND BOTH VALUES exist
        IF pnPromotionTypeVal = 2 AND pdPromotionValueNum > pdCurrentTimestampVal AND pdPromotionValueNum IS NOT NULL AND pdPromotionValueNum2 IS NOT NULL THEN
            
            -- Step 5: UPDATE subscription_purchase.end_date AND start_date for users IN group_user
            UPDATE preflow_41.subscription_purchase sp
            SET sp.start_date = pdCurrentTimestampVal,
                sp.end_date = pdPromotionValueNum,
                sp.updated_date = pdCurrentTimestampVal
            WHERE sp.is_current = 1
                AND sp.created_date <= pdPromotionValueNum2
                AND sp.sub_id != 'ea0f0fa86f3320eac0a8155a4cc0b8e563dd'
                AND NOT EXISTS (
                    SELECT 1 
                    FROM preflow_41.OTE_user_skip_force_subscription ote 
                    WHERE ote.user_id = sp.user_id
                );
            
            -- GET number of updated rows FROM subscription_purchase
            SET pnUpdatedRows = ROW_COUNT();
            
            -- Step 6: UPDATE flo_subscription.purchases for users WITH paid plans (exclude free plan)
            UPDATE flo_subscription.purchases pu
            SET pu.expires_at = FROM_UNIXTIME(pdPromotionValueNum),
                pu.grace_period_at = FROM_UNIXTIME(pdPromotionValueNum),
                pu.next_renewal_date = FROM_UNIXTIME(pdPromotionValueNum),
                pu.last_renewal_date = FROM_UNIXTIME(pdCurrentTimestampVal)
            WHERE pu.is_current = 1
                AND pu.product_id != 'ea0f0fa86f3320eac0a8155a4cc0b8e563dd'
                AND NOT EXISTS (
                    SELECT 1 
                    FROM preflow_41.OTE_user_skip_force_subscription ote 
                    WHERE ote.user_id = pu.user_id
                );
            
            -- ADD updated rows FROM purchases TO total count
            SET pnUpdatedRows = pnUpdatedRows + ROW_COUNT();
            
            -- Commit transaction
            COMMIT;
            
            -- SHOW result
            SELECT CONCAT('Successfully updated ', pnUpdatedRows, ' records') AS result;
            
        ELSE
            -- Conditions NOT met
            SELECT 'Promotion conditions NOT met' AS result;
        END IF;
    END IF;
    
END