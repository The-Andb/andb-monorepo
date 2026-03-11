CREATE PROCEDURE `OTE_migrateUsagesCallDuration_V2`(
    IN psEmail VARCHAR(255)  -- NULL OR empty = migrate ALL users, otherwise migrate SPECIFIC user BY email
)
BEGIN
    DECLARE pnTotalUsers INT DEFAULT 0;
    DECLARE pnEligibleUsers INT DEFAULT 0;
    DECLARE pnUpdatedCount INT DEFAULT 0;
    DECLARE pnTargetUserId BIGINT DEFAULT NULL;
    
    -- IF email provided, GET user_id
    IF psEmail IS NOT NULL AND psEmail != '' THEN
        SELECT user_id INTO pnTargetUserId
        FROM app_account_token
        WHERE email = psEmail COLLATE utf8mb4_unicode_ci
        LIMIT 1;
        
        IF pnTargetUserId IS NULL THEN
            SELECT CONCAT('ERROR: User NOT found WITH email: ', psEmail) AS error_message;
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'User NOT found';
        END IF;
        
        SELECT CONCAT('Migrating single user: ', psEmail, ' (ID: ', pnTargetUserId, ')') AS mode;
    ELSE
        SELECT 'Migrating ALL users' AS mode;
    END IF;
    
    -- GET total users WITH component type 3
    SELECT COUNT(DISTINCT u.user_id) INTO pnTotalUsers
    FROM usages u
    INNER JOIN components c ON u.component_id = c.id AND c.type = 3
    WHERE u.is_active = 1
    AND (pnTargetUserId IS NULL OR u.user_id = pnTargetUserId);
    
    -- GET eligible users (WHERE plan_details.component_value = usages.used_value)
    SELECT COUNT(DISTINCT u.user_id) INTO pnEligibleUsers
    FROM usages u
    INNER JOIN components c ON u.component_id = c.id AND c.type = 3
INNER JOIN orders o ON u.user_id = o.user_id AND o.is_active = 1
INNER JOIN plan_details pd ON o.plan_id = pd.plan_id AND pd.component_id = c.id
    WHERE u.is_active = 1
    AND u.used_value = pd.component_value
    AND (pnTargetUserId IS NULL OR u.user_id = pnTargetUserId);
    
    -- SHOW migration info
    SELECT '=== CALL DURATION USAGES MIGRATION STARTED ===' AS header;
    SELECT 
        pnTotalUsers AS total_users_with_component_type_3,
        pnEligibleUsers AS eligible_users_to_migrate;
    
    -- Step 1: UPDATE usages for component type = 3 (CALL_DURATION)
    -- Only UPDATE users WHERE usages.used_value = plan_details.component_value
    -- SET used_value TO 0 (reset CALL duration USAGE)
    UPDATE usages u
    INNER JOIN components c ON u.component_id = c.id AND c.type = 3
INNER JOIN orders o ON u.user_id = o.user_id AND o.is_active = 1
INNER JOIN plan_details pd ON o.plan_id = pd.plan_id AND pd.component_id = c.id
    SET 
        u.used_value = 0,
        u.updated_date = CURRENT_TIMESTAMP(3)
    WHERE u.is_active = 1
    AND u.used_value = pd.component_value
    AND (pnTargetUserId IS NULL OR u.user_id = pnTargetUserId);
    
    SET pnUpdatedCount = ROW_COUNT();
    
    -- SHOW results
    SELECT '=== MIGRATION COMPLETED ===' AS result_header;
    SELECT 
        pnUpdatedCount AS usages_updated,
        pnEligibleUsers AS eligible_users,
        pnTotalUsers AS total_users_with_component_type_3;
    
END