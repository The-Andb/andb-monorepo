CREATE PROCEDURE `m2025_migrateUsersToPremiumYearly`(
    IN psUserEmails TEXT,         -- NULL = migrate ALL, otherwise comma-separated list of emails
    IN pdExpireAt DATETIME        -- NULL = 1 year FROM now, otherwise must be > NOW()
)
main_block: BEGIN
    DECLARE pnTotalUsers INT DEFAULT 0;
    DECLARE pnSuccessCount INT DEFAULT 0;
    DECLARE pnFailedCount INT DEFAULT 0;
    DECLARE psSubId VARCHAR(255);
    DECLARE pnPlanId BIGINT;
    DECLARE pnOrderNumber INT;
    DECLARE psPurchaseDate DATETIME DEFAULT NOW();
    DECLARE psExpiresAt DATETIME;
    DECLARE pnNewOrderId BIGINT;  -- Store LAST_INSERT_ID() for faster lookups
    
    -- Normalized email list (lowercase, no spaces)
    DECLARE psNormalizedEmails TEXT DEFAULT NULL;
    
    -- CURSOR variables
    DECLARE pnCurrentUserId BIGINT;
    DECLARE psCurrentEmail VARCHAR(255);
    DECLARE pbDone INT DEFAULT 0;
    DECLARE pbHasError INT DEFAULT 0;
    
    -- Error diagnostics variables
    DECLARE psErrorMessage TEXT DEFAULT '';
    DECLARE psErrorSQLState VARCHAR(5) DEFAULT '';
    DECLARE pnErrorCode INT DEFAULT 0;
    DECLARE psCurrentStep VARCHAR(50) DEFAULT '';
    
    -- CURSOR for iterating users
    -- USING DISTINCT TO prevent DUPLICATE processing IF user has multiple purchases/orders
    DECLARE user_cursor CURSOR FOR
        SELECT DISTINCT aat.user_id, aat.email
        FROM flo_subscription.app_account_token aat
        LEFT JOIN preflow_41.user_deleted ud ON aat.user_id = ud.user_id
        WHERE ud.id IS NULL
          AND aat.email IS NOT NULL AND TRIM(aat.email) != ''
          AND (psNormalizedEmails IS NULL OR FIND_IN_SET(LOWER(TRIM(aat.email)) COLLATE utf8mb4_unicode_ci, psNormalizedEmails COLLATE utf8mb4_unicode_ci) > 0);
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET pbDone = 1;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            psErrorSQLState = RETURNED_SQLSTATE,
            pnErrorCode = MYSQL_ERRNO,
            psErrorMessage = MESSAGE_TEXT;
        SET pbHasError = 1;
    END;
    
    -- ========================================================================
    -- Normalize email list (remove spaces, CONVERT TO lowercase)
    -- ========================================================================
    IF psUserEmails IS NOT NULL AND TRIM(psUserEmails) != '' THEN
        -- Remove spaces around commas AND CONVERT TO lowercase
        SET psNormalizedEmails = LOWER(REPLACE(REPLACE(REPLACE(psUserEmails, ' ', ''), '\r', ''), '\n', ''));
    END IF;
    
    -- ========================================================================
    -- Validate AND SET expiry date
    -- ========================================================================
    IF pdExpireAt IS NULL THEN
        -- DEFAULT: 1 year FROM now
        SET psExpiresAt = DATE_ADD(NOW(), INTERVAL 1 YEAR);
    ELSEIF pdExpireAt > NOW() THEN
        -- USE provided date
        SET psExpiresAt = pdExpireAt;
    ELSE
        -- Invalid: expire date must be IN the future
        SELECT 'ERROR: pdExpireAt must be greater than NOW()' AS error_message;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid pdExpireAt: must be a future date';
    END IF;
    
    -- ========================================================================
    -- GET Premium Yearly subscription ID AND plan info FROM plans TABLE
    -- ========================================================================
    SELECT product_id, id, order_number INTO psSubId, pnPlanId, pnOrderNumber
    FROM flo_subscription.plans
    WHERE circle_life = 'yearly' AND plan_group = 3 AND is_active = 1
    LIMIT 1;
    
    IF psSubId IS NULL THEN
        SELECT 'ERROR: Premium Yearly plan NOT found IN plans TABLE' AS error_message;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Premium Yearly plan NOT found';
    END IF;
    
    -- ========================================================================
    -- Count users TO migrate
    -- ========================================================================
    SELECT COUNT(DISTINCT aat.user_id) INTO pnTotalUsers
    FROM flo_subscription.app_account_token aat
    LEFT JOIN preflow_41.user_deleted ud ON aat.user_id = ud.user_id
    WHERE ud.id IS NULL
      AND aat.email IS NOT NULL AND TRIM(aat.email) != ''
      AND (psNormalizedEmails IS NULL OR FIND_IN_SET(LOWER(TRIM(aat.email)) COLLATE utf8mb4_unicode_ci, psNormalizedEmails COLLATE utf8mb4_unicode_ci) > 0);
    
    IF pnTotalUsers = 0 THEN
        SELECT 'ERROR: No users found TO migrate' AS error_message;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No users found TO migrate';
    END IF;
    
    -- ========================================================================
    -- SHOW migration info
    -- ========================================================================
    SELECT '=== PREMIUM YEARLY MIGRATION STARTED ===' AS header;
    SELECT 
        IFNULL(psUserEmails, 'ALL USERS') AS migration_mode,
        pnTotalUsers AS total_users,
        psSubId AS subscription_id,
        pnPlanId AS plan_id,
        pnOrderNumber AS order_number,
        psPurchaseDate AS purchase_date,
        psExpiresAt AS expires_at,
        CASE WHEN pdExpireAt IS NULL THEN 'DEFAULT (1 year)' ELSE 'Custom' END AS expiry_source;
    
    -- ========================================================================
    -- Process users one BY one WITH transaction
    -- ========================================================================
    OPEN user_cursor;
    
    user_loop: LOOP
        FETCH user_cursor INTO pnCurrentUserId, psCurrentEmail;
        IF pbDone THEN
            LEAVE user_loop;
        END IF;
        
        -- Reset error flag AND step tracker
        SET pbHasError = 0;
        SET psCurrentStep = '';
        SET psErrorMessage = '';
        SET psErrorSQLState = '';
        SET pnErrorCode = 0;
        
        -- Start transaction for this user
        START TRANSACTION;
        
        -- ====================================================================
        -- OLD SUBSCRIPTION SYSTEM (preflow_41) - Only report_cached_user
        -- Note: subscription_purchase IS deprecated
        -- ====================================================================
        
        -- Step 1: UPDATE report_cached_user (WITH order_number) - USE user_id for INDEX
        SET psCurrentStep = 'Step1_UpdateReportCachedUser';
        UPDATE preflow_41.report_cached_user rcu
        SET rcu.subs_type = 2, 
            rcu.sub_id = psSubId, 
            rcu.order_number = pnOrderNumber,
            rcu.updated_date = UNIX_TIMESTAMP()
        WHERE rcu.user_id = pnCurrentUserId;
        
        -- ====================================================================
        -- NEW SUBSCRIPTION SYSTEM (flo_subscription)
        -- ====================================================================
        
        -- Step 2: Deactivate old purchases
        SET psCurrentStep = 'Step2_DeactivateOldPurchases';
        UPDATE flo_subscription.purchases p
        SET p.status = 0, p.is_current = 0, p.updated_date = NOW()
        WHERE p.user_id = pnCurrentUserId AND p.is_current = 1;
        
        -- Step 3: Deactivate old orders
        SET psCurrentStep = 'Step3_DeactivateOldOrders';
        UPDATE flo_subscription.orders o
        SET o.is_active = 0, o.updated_date = NOW()
        WHERE o.user_id = pnCurrentUserId AND o.is_active = 1;
        
        -- Step 4: Deactivate old usages
        SET psCurrentStep = 'Step4_DeactivateOldUsages';
        UPDATE flo_subscription.usages us
        SET us.is_active = 0, us.updated_date = NOW()
        WHERE us.user_id = pnCurrentUserId AND us.is_active = 1;
        
        -- Step 5: Remove alerts for this user
        SET psCurrentStep = 'Step5_RemoveAlerts';
        DELETE FROM flo_subscription.alert
        WHERE user_id = pnCurrentUserId;
        
        -- Step 6: Remove user_usage_warnings for this user
        SET psCurrentStep = 'Step6_RemoveUserUsageWarnings';
        DELETE FROM flo_subscription.user_usage_warnings
        WHERE user_id = pnCurrentUserId;
        
        -- Step 7: CREATE new ORDER AND capture LAST_INSERT_ID()
        SET psCurrentStep = 'Step7_CreateNewOrder';
        INSERT INTO flo_subscription.orders (plan_id, user_id, is_active, name, price, period, auto_renew, description, subs_type, order_number, created_date, updated_date)
        SELECT pl.id, pnCurrentUserId, 1, pl.name, pl.price, pl.period, 0, pl.description, 2, pl.order_number, NOW(), NOW()
        FROM flo_subscription.plans pl
        WHERE pl.id = pnPlanId
        LIMIT 1;
        
        SET pnNewOrderId = LAST_INSERT_ID();
        
        -- Step 8: CREATE order_details (USE pnNewOrderId directly)
        SET psCurrentStep = 'Step8_CreateOrderDetails';
        INSERT INTO flo_subscription.order_details (order_id, component_id, component_value, description, created_date, updated_date)
        SELECT pnNewOrderId, pd.component_id, pd.component_value, pd.description, NOW(), NOW()
        FROM flo_subscription.plan_details pd
        WHERE pd.plan_id = pnPlanId;
        
        -- Step 9: CREATE new usages (optimized: USE pnPlanId directly, simplified old USAGE lookup)
        SET psCurrentStep = 'Step9_CreateNewUsages';
        INSERT INTO flo_subscription.usages (user_id, component_id, used_value, used_data, description, is_active, created_date, updated_date)
        SELECT 
            pnCurrentUserId, 
            pd.component_id,
            COALESCE(latest_u.used_value, pd.component_value),
            latest_u.used_data,
            pd.description, 
            1, 
            NOW(), 
            NOW()
        FROM flo_subscription.plan_details pd
        LEFT JOIN (
            SELECT u.component_id, u.used_value, u.used_data
            FROM flo_subscription.usages u
            INNER JOIN (
                SELECT component_id, MAX(id) AS max_id
                FROM flo_subscription.usages
                WHERE user_id = pnCurrentUserId
                GROUP BY component_id
            ) max_u ON u.id = max_u.max_id
        ) latest_u ON pd.component_id = latest_u.component_id
        WHERE pd.plan_id = pnPlanId;
        
        -- Step 10: CREATE new purchase (USE pnNewOrderId directly)
        SET psCurrentStep = 'Step10_CreateNewPurchase';
        INSERT INTO flo_subscription.purchases (user_id, order_id, transaction_id, description, purchase_date, is_current, purchase_platform, product_id, status, grace_period_at, expires_at, last_renewal_date, next_renewal_date, last_transaction_uid, created_date, updated_date)
        SELECT pnCurrentUserId, pnNewOrderId, 0, pl.description, psPurchaseDate, 1, 4, psSubId, 1, psExpiresAt, psExpiresAt, psPurchaseDate, psExpiresAt, '', NOW(), NOW()
        FROM flo_subscription.plans pl
        WHERE pl.id = pnPlanId;
        
        -- Step 11: Upsert api_last_modified for subscription_usage
        SET psCurrentStep = 'Step11_UpsertApiLastModified';
        INSERT INTO preflow_41.api_last_modified (user_id, api_name, api_modified_date, created_date, updated_date)
        VALUES (pnCurrentUserId, 'subscription_usage', UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), UNIX_TIMESTAMP())
        ON DUPLICATE KEY UPDATE
            api_modified_date = UNIX_TIMESTAMP(),
            updated_date = UNIX_TIMESTAMP();
        
        -- CHECK IF error occurred
        IF pbHasError THEN
            ROLLBACK;
            SET pnFailedCount = pnFailedCount + 1;
            SELECT 
                'ROLLBACK' AS status,
                pnCurrentUserId AS user_id,
                psCurrentEmail AS email,
                psCurrentStep AS failed_at_step,
                pnErrorCode AS error_code,
                psErrorSQLState AS sql_state,
                psErrorMessage AS error_message;
        ELSE
            COMMIT;
            SET pnSuccessCount = pnSuccessCount + 1;
        END IF;
        
    END LOOP user_loop;
    
    CLOSE user_cursor;
    
    -- ========================================================================
    -- Final summary
    -- ========================================================================
    SELECT '=== MIGRATION COMPLETED ===' AS result_header;
    SELECT 
        IFNULL(psUserEmails, 'ALL USERS') AS migration_mode,
        pnTotalUsers AS total_users,
        pnSuccessCount AS success_count,
        pnFailedCount AS failed_count,
        psSubId AS subscription_id,
        CASE 
            WHEN pnFailedCount = 0 THEN CONCAT('Successfully migrated ', pnSuccessCount, ' users')
            ELSE CONCAT('Migrated ', pnSuccessCount, ' users, ', pnFailedCount, ' failed')
        END AS status;
    
END