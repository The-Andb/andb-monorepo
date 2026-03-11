CREATE PROCEDURE `OTE_migrateUsages3rdAccount_V2`(
    IN psEmail VARCHAR(255)  -- NULL OR empty = migrate ALL users, otherwise migrate SPECIFIC user BY email
)
BEGIN
    DECLARE pnTotalUsers INT DEFAULT 0;
    DECLARE pnThirdPartyAccRecords INT DEFAULT 0;
    DECLARE pnUpdatedCount INT DEFAULT 0;
    DECLARE pnTargetUserId BIGINT DEFAULT NULL;
    
    -- IF email provided, GET user_id
    IF psEmail IS NOT NULL AND psEmail != '' THEN
        SELECT user_id INTO pnTargetUserId
        FROM flo_subscription.app_account_token
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
    
    -- GET counts
    SELECT COUNT(DISTINCT tpa.user_id) INTO pnTotalUsers
    FROM preflow_41.third_party_account tpa
    INNER JOIN flo_subscription.app_account_token aat ON tpa.user_id = aat.user_id
    WHERE (pnTargetUserId IS NULL OR tpa.user_id = pnTargetUserId);
    
    SELECT COUNT(*) INTO pnThirdPartyAccRecords
    FROM preflow_41.third_party_account tpa
    INNER JOIN flo_subscription.app_account_token aat ON tpa.user_id = aat.user_id
    WHERE (pnTargetUserId IS NULL OR tpa.user_id = pnTargetUserId);
    
    -- SHOW migration info
    SELECT '=== THIRD PARTY ACCOUNT USAGES MIGRATION STARTED ===' AS header;
    SELECT 
        pnTotalUsers AS total_users_with_third_party_accounts,
        pnThirdPartyAccRecords AS total_third_party_account_records;
    
    -- Step 1: UPDATE existing usages records WITH third_party_account count (only active usages)
    -- Uses LEFT JOIN so users without TPA will have used_value = 0 AND used_data = NULL
    UPDATE flo_subscription.usages u
    INNER JOIN flo_subscription.components c ON u.component_id = c.id AND c.type = 1
    INNER JOIN flo_subscription.app_account_token aat ON u.user_id = aat.user_id
    LEFT JOIN (
        SELECT 
            tpa.user_id,
            COUNT(tpa.id) AS account_count,
            JSON_ARRAYAGG(
                JSON_OBJECT(
                    'id', tpa.id,
                    'type_income', tpa.type_income,
                    'user_income', tpa.user_income
                )
            ) AS used_data_json
        FROM preflow_41.third_party_account tpa
        GROUP BY tpa.user_id
    ) AS tpa_agg ON u.user_id = tpa_agg.user_id
    SET 
        u.used_value = COALESCE(tpa_agg.account_count, 0),
        u.used_data = tpa_agg.used_data_json,
        u.updated_date = CURRENT_TIMESTAMP(3)
    WHERE u.is_active = 1
    AND (pnTargetUserId IS NULL OR u.user_id = pnTargetUserId);
    
    SET pnUpdatedCount = ROW_COUNT();
    
    -- SHOW results
    SELECT '=== MIGRATION COMPLETED ===' AS result_header;
    SELECT 
        pnUpdatedCount AS usages_updated,
        pnThirdPartyAccRecords AS total_third_party_account_records;
    
END