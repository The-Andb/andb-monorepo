CREATE PROCEDURE `m2025_migrateNonPremiumYearlyToPremiumYearly`(
    IN psUserEmails TEXT,         -- NULL = migrate ALL non-Premium-Yearly users, otherwise comma-separated list
    IN pdExpireAt DATETIME        -- NULL = 1 year FROM now, otherwise must be > NOW()
)
BEGIN
    -- This PROCEDURE migrates users WITH order_number > 1 (OR no plan) TO Premium Yearly
    
    DECLARE pnTotalUsers INT DEFAULT 0;
    DECLARE pnSuccessCount INT DEFAULT 0;
    DECLARE pnFailedCount INT DEFAULT 0;
    DECLARE psSubId VARCHAR(255);
    DECLARE pnPlanId BIGINT;
    DECLARE psPurchaseDate DATETIME DEFAULT NOW();
    DECLARE psExpiresAt DATETIME;
    
    DECLARE psNormalizedEmails TEXT DEFAULT NULL;
    DECLARE pnCurrentUserId BIGINT;
    DECLARE psCurrentEmail VARCHAR(255);
    DECLARE pbDone INT DEFAULT 0;
    DECLARE pbHasError INT DEFAULT 0;
    
    DECLARE psErrorMessage TEXT DEFAULT '';
    DECLARE psErrorSQLState VARCHAR(5) DEFAULT '';
    DECLARE pnErrorCode INT DEFAULT 0;
    DECLARE psCurrentStep VARCHAR(50) DEFAULT '';
    
    -- CURSOR: Only SELECT users WHERE order_number > 1 OR no plan (order_number IS NULL)
    DECLARE user_cursor CURSOR FOR
        SELECT DISTINCT aat.user_id, aat.email
        FROM flo_subscription.app_account_token aat
        LEFT JOIN preflow_41.user_deleted ud ON aat.user_id = ud.user_id
        LEFT JOIN flo_subscription.purchases p ON p.user_id = aat.user_id AND p.is_current = 1
        LEFT JOIN flo_subscription.orders o ON o.id = p.order_id AND o.is_active = 1
        LEFT JOIN flo_subscription.plans cur_pl ON cur_pl.id = o.plan_id
        WHERE ud.id IS NULL
          AND aat.email IS NOT NULL AND TRIM(aat.email) != ''
          AND (psNormalizedEmails IS NULL OR FIND_IN_SET(LOWER(TRIM(aat.email)) COLLATE utf8mb4_unicode_ci, psNormalizedEmails COLLATE utf8mb4_unicode_ci) > 0)
          AND (cur_pl.order_number IS NULL OR cur_pl.order_number > 1);  -- NOT Premium Yearly
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET pbDone = 1;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            psErrorSQLState = RETURNED_SQLSTATE,
            pnErrorCode = MYSQL_ERRNO,
            psErrorMessage = MESSAGE_TEXT;
        SET pbHasError = 1;
    END;
    
    -- Normalize email list
    IF psUserEmails IS NOT NULL AND TRIM(psUserEmails) != '' THEN
        SET psNormalizedEmails = LOWER(REPLACE(REPLACE(REPLACE(psUserEmails, ' ', ''), '\r', ''), '\n', ''));
    END IF;
    
    -- Validate AND SET expiry date
    IF pdExpireAt IS NULL THEN
        SET psExpiresAt = DATE_ADD(NOW(), INTERVAL 1 YEAR);
    ELSEIF pdExpireAt > NOW() THEN
        SET psExpiresAt = pdExpireAt;
    ELSE
        SELECT 'ERROR: pdExpireAt must be greater than NOW()' AS error_message;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid pdExpireAt: must be a future date';
    END IF;
    
    -- GET Premium Yearly plan info
    SELECT product_id, id INTO psSubId, pnPlanId
    FROM flo_subscription.plans
    WHERE circle_life = 'yearly' AND plan_group = 3 AND is_active = 1
    LIMIT 1;
    
    IF psSubId IS NULL THEN
        SELECT 'ERROR: Premium Yearly plan NOT found' AS error_message;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Premium Yearly plan NOT found';
    END IF;
    
    -- Count users TO migrate (only non-Premium-Yearly)
    SELECT COUNT(DISTINCT aat.user_id) INTO pnTotalUsers
    FROM flo_subscription.app_account_token aat
    LEFT JOIN preflow_41.user_deleted ud ON aat.user_id = ud.user_id
    LEFT JOIN flo_subscription.purchases p ON p.user_id = aat.user_id AND p.is_current = 1
    LEFT JOIN flo_subscription.orders o ON o.id = p.order_id AND o.is_active = 1
    LEFT JOIN flo_subscription.plans cur_pl ON cur_pl.id = o.plan_id
    WHERE ud.id IS NULL
      AND aat.email IS NOT NULL AND TRIM(aat.email) != ''
      AND (psNormalizedEmails IS NULL OR FIND_IN_SET(LOWER(TRIM(aat.email)) COLLATE utf8mb4_unicode_ci, psNormalizedEmails COLLATE utf8mb4_unicode_ci) > 0)
      AND (cur_pl.order_number IS NULL OR cur_pl.order_number > 1);
    
    IF pnTotalUsers = 0 THEN
        SELECT 'No non-Premium-Yearly users found TO migrate' AS message;
        -- Don't error, just RETURN
    ELSE
        SELECT '=== NON-PREMIUM-YEARLY MIGRATION STARTED ===' AS header;
        SELECT 
            IFNULL(psUserEmails, 'ALL NON-PREMIUM-YEARLY USERS') AS migration_mode,
            'order_number > 1 OR no plan' AS filter,
            pnTotalUsers AS total_users,
            psSubId AS target_subscription_id,
            pnPlanId AS target_plan_id,
            psExpiresAt AS expires_at;
        
        -- CALL the main migration PROCEDURE WITH psBasePlan = NULL (it will process ALL)
        -- But we've already filtered IN our CURSOR, so we process here directly
        OPEN user_cursor;
        
        user_loop: LOOP
            FETCH user_cursor INTO pnCurrentUserId, psCurrentEmail;
            IF pbDone THEN
                LEAVE user_loop;
            END IF;
            
            SET pbHasError = 0;
            SET psCurrentStep = '';
            
            START TRANSACTION;
            
            -- Step 1: UPDATE report_cached_user (DOUBLE(13,3) = seconds WITH millisecond PRECISION)
            SET psCurrentStep = 'Step1_UpdateReportCachedUser';
            UPDATE preflow_41.report_cached_user
            SET next_renewal = UNIX_TIMESTAMP(psExpiresAt),
                subs_type = 2,  -- Premium
                order_number = 1,
                updated_date = UNIX_TIMESTAMP()
            WHERE user_id = pnCurrentUserId;
            
            -- Step 2: Deactivate old orders
            SET psCurrentStep = 'Step2_DeactivateOldOrders';
            UPDATE flo_subscription.orders
            SET is_active = 0, updated_date = NOW()
            WHERE user_id = pnCurrentUserId AND is_active = 1;
            
            -- Step 3: Deactivate old purchases
            SET psCurrentStep = 'Step3_DeactivateOldPurchases';
            UPDATE flo_subscription.purchases
            SET is_current = 0, updated_date = NOW()
            WHERE user_id = pnCurrentUserId AND is_current = 1;
            
            -- Step 4: Deactivate old usages
            SET psCurrentStep = 'Step4_DeactivateOldUsages';
            UPDATE flo_subscription.usages
            SET is_active = 0, updated_date = NOW()
            WHERE user_id = pnCurrentUserId AND is_active = 1;
            
            -- Step 5: Remove alerts
            SET psCurrentStep = 'Step5_RemoveAlerts';
            DELETE FROM flo_subscription.alert WHERE user_id = pnCurrentUserId;
            
            -- Step 6: Remove warnings
            SET psCurrentStep = 'Step6_RemoveWarnings';
            DELETE FROM flo_subscription.user_usage_warnings WHERE user_id = pnCurrentUserId;
            
            -- Step 7: INSERT new ORDER
            SET psCurrentStep = 'Step7_InsertOrder';
            INSERT INTO flo_subscription.orders (user_id, plan_id, name, price, period, description, is_active, created_date, updated_date)
            SELECT pnCurrentUserId, pnPlanId, pl.name, pl.price, pl.period, pl.description, 1, NOW(), NOW()
            FROM flo_subscription.plans pl WHERE pl.id = pnPlanId;
            
            -- Step 8: INSERT ORDER details
            SET psCurrentStep = 'Step8_InsertOrderDetails';
            INSERT INTO flo_subscription.order_details (order_id, component_id, component_value, description, created_date, updated_date)
            SELECT LAST_INSERT_ID(), pd.component_id, pd.component_value, pd.description, NOW(), NOW()
            FROM flo_subscription.plan_details pd WHERE pd.plan_id = pnPlanId;
            
            -- Step 9: INSERT new purchase
            SET psCurrentStep = 'Step9_InsertPurchase';
            INSERT INTO flo_subscription.purchases 
                (user_id, order_id, transaction_id, description, purchase_date, is_current, purchase_platform, 
                 product_id, status, grace_period_at, expires_at, last_renewal_date, next_renewal_date, 
                 last_transaction_uid, created_date, updated_date)
            SELECT pnCurrentUserId, o.id, 0, pl.description, psPurchaseDate, 1, 4, 
                   psSubId, 1, psExpiresAt, psExpiresAt, psPurchaseDate, psExpiresAt, '', NOW(), NOW()
            FROM flo_subscription.orders o
            INNER JOIN flo_subscription.plans pl ON pl.id = o.plan_id
            WHERE o.user_id = pnCurrentUserId AND o.is_active = 1
            LIMIT 1;
            
            -- Step 10: INSERT new usages (optimized: uses JOIN instead of ORDER BY subqueries)
            SET psCurrentStep = 'Step10_InsertUsages';
            INSERT INTO flo_subscription.usages (user_id, component_id, used_value, used_data, description, is_active, created_date, updated_date)
            SELECT pnCurrentUserId, pd.component_id, 
                   COALESCE(latest_u.used_value, pd.component_value),
                   latest_u.used_data,
                   pd.description, 1, NOW(), NOW()
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
            
            -- Step 11: Upsert api_last_modified for subscription_usage
            SET psCurrentStep = 'Step11_UpsertApiLastModified';
            INSERT INTO preflow_41.api_last_modified (user_id, api_name, api_modified_date, created_date, updated_date)
            VALUES (pnCurrentUserId, 'subscription_usage', UNIX_TIMESTAMP(), UNIX_TIMESTAMP(), UNIX_TIMESTAMP())
            ON DUPLICATE KEY UPDATE
                api_modified_date = UNIX_TIMESTAMP(),
                updated_date = UNIX_TIMESTAMP();
            
            IF pbHasError THEN
                ROLLBACK;
                SET pnFailedCount = pnFailedCount + 1;
                SELECT 'ROLLBACK' AS status, pnCurrentUserId AS user_id, psCurrentEmail AS email,
                       psCurrentStep AS failed_at, pnErrorCode AS error_code, psErrorMessage AS error_msg;
            ELSE
                COMMIT;
                SET pnSuccessCount = pnSuccessCount + 1;
            END IF;
        END LOOP;
        
        CLOSE user_cursor;
        
        SELECT '=== MIGRATION COMPLETED ===' AS result;
        SELECT pnSuccessCount AS success_count, pnFailedCount AS failed_count, 
               pnTotalUsers AS total_processed,
               CASE WHEN pnFailedCount = 0 THEN 'ALL users migrated successfully'
                    ELSE CONCAT('Migrated ', pnSuccessCount, ', failed ', pnFailedCount)
               END AS status;
    END IF;
END