CREATE PROCEDURE `OTE_migrateUsages3rdAccount`()
BEGIN
    DECLARE pnTotalUsers INT DEFAULT 0;
    DECLARE pnThirdPartyAccRecords INT DEFAULT 0;
    DECLARE pnUsagesToCreate INT DEFAULT 0;
    DECLARE pnCreatedCount INT DEFAULT 0;
    DECLARE pnUpdatedCount INT DEFAULT 0;
    
    -- GET counts
    SELECT COUNT(DISTINCT tpa.user_id) INTO pnTotalUsers
    FROM preflow_41.third_party_account tpa
    INNER JOIN flo_subscription.app_account_token aat ON tpa.user_id = aat.user_id;
    
    SELECT COUNT(*) INTO pnThirdPartyAccRecords
    FROM preflow_41.third_party_account tpa
    INNER JOIN flo_subscription.app_account_token aat ON tpa.user_id = aat.user_id;
    
    SELECT COUNT(*) INTO pnUsagesToCreate
    FROM (
        SELECT DISTINCT tpa.user_id
        FROM preflow_41.third_party_account tpa
        INNER JOIN flo_subscription.app_account_token aat ON tpa.user_id = aat.user_id
        WHERE NOT EXISTS (
            SELECT 1 
            FROM flo_subscription.usages u 
            WHERE u.user_id = tpa.user_id AND u.component_id = 1
        )
    ) AS missing_users;
    
    -- SHOW migration info
    SELECT '=== THIRD PARTY ACCOUNT USAGES MIGRATION STARTED ===' AS header;
    SELECT 
        pnTotalUsers AS total_users_with_third_party_accounts,
        pnThirdPartyAccRecords AS total_third_party_account_records,
        pnUsagesToCreate AS usages_to_create;
    
    -- Step 1: INSERT missing usages records for users WITH third_party_account
    -- Count third_party_account records per user_id AND SET AS used_value
    INSERT INTO flo_subscription.usages (
        user_id,
        component_id,
        used_value,
        used_data,
        description,
        mail_bytes,
        cal_bytes,
        card_bytes,
        file_note_bytes,
        file_comment_bytes,
        file_chat_bytes,
        file_contact_bytes,
        qa_bytes,
        is_active
    )
    SELECT 
        tpa_agg.user_id,
        1 AS component_id,
        tpa_agg.account_count AS used_value,
        NULL AS used_data,
        CONCAT('Migrated FROM third_party_account: ', tpa_agg.account_count, ' account(s)') AS description,
        0 AS mail_bytes,
        0 AS cal_bytes,
        0 AS card_bytes,
        0 AS file_note_bytes,
        0 AS file_comment_bytes,
        0 AS file_chat_bytes,
        0 AS file_contact_bytes,
        0 AS qa_bytes,
        1 AS is_active
    FROM (
        SELECT 
            tpa.user_id,
            COUNT(tpa.id) AS account_count
        FROM preflow_41.third_party_account tpa
        INNER JOIN flo_subscription.app_account_token aat ON tpa.user_id = aat.user_id
        WHERE NOT EXISTS (
            SELECT 1 
            FROM flo_subscription.usages u 
            WHERE u.user_id = tpa.user_id AND u.component_id = 1
        )
        GROUP BY tpa.user_id
    ) AS tpa_agg;
    
    SET pnCreatedCount = ROW_COUNT();
    
    -- Step 2: UPDATE existing usages records WITH third_party_account count (only active usages)
    UPDATE flo_subscription.usages u
    INNER JOIN flo_subscription.app_account_token aat ON u.user_id = aat.user_id
    INNER JOIN (
        SELECT 
            tpa.user_id,
            COUNT(tpa.id) AS account_count
        FROM preflow_41.third_party_account tpa
        INNER JOIN flo_subscription.app_account_token aat ON tpa.user_id = aat.user_id
        GROUP BY tpa.user_id
    ) AS tpa_agg ON u.user_id = tpa_agg.user_id
    SET 
        u.used_value = tpa_agg.account_count,
        u.updated_date = CURRENT_TIMESTAMP(3)
    WHERE u.component_id = 1
    AND u.is_active = 1;
    
    SET pnUpdatedCount = ROW_COUNT();
    
    -- SHOW results
    SELECT '=== MIGRATION COMPLETED ===' AS result_header;
    SELECT 
        pnCreatedCount AS usages_created,
        pnUpdatedCount AS usages_updated,
        pnThirdPartyAccRecords AS total_third_party_account_records_migrated,
        CASE 
            WHEN pnCreatedCount = pnUsagesToCreate THEN 'ALL usages created successfully'
            ELSE CONCAT('WARNING: Expected ', pnUsagesToCreate, ' but created ', pnCreatedCount)
        END AS status;
    
END