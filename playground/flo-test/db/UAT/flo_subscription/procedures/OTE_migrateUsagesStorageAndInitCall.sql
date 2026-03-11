CREATE PROCEDURE `OTE_migrateUsagesStorageAndInitCall`()
BEGIN
    DECLARE pnTotalUsers INT DEFAULT 0;
    DECLARE pnTotalComponents INT DEFAULT 0;
    DECLARE pnUsagesToCreate INT DEFAULT 0;
    DECLARE pnCreatedCount INT DEFAULT 0;
    DECLARE pnQuotaUpdatedCount INT DEFAULT 0;
    
    -- GET counts (optimized: combine WHERE possible)
    SELECT 
        COUNT(DISTINCT aat.user_id) INTO pnTotalUsers 
    FROM flo_subscription.app_account_token aat;
    
    SELECT COUNT(*) INTO pnTotalComponents FROM flo_subscription.components;
    
    -- Optimized: USE NOT EXISTS instead of LEFT JOIN for better performance
    -- Only count for component_id = 1 AND 2
    SELECT COUNT(*) INTO pnUsagesToCreate
    FROM flo_subscription.app_account_token aat
    INNER JOIN flo_subscription.orders o ON aat.user_id = o.user_id
    INNER JOIN flo_subscription.plan_details pd ON o.plan_id = pd.plan_id
    INNER JOIN flo_subscription.components c ON pd.component_id = c.id
    WHERE c.id IN (2, 3)
    AND NOT EXISTS (
        SELECT 1 
        FROM flo_subscription.usages u 
        WHERE u.user_id = aat.user_id AND u.component_id = c.id
    );
    
    -- SHOW migration info
    SELECT '=== USAGES MIGRATION STARTED ===' AS header;
    SELECT 
        pnTotalUsers AS total_users,
        pnTotalComponents AS total_components,
        pnUsagesToCreate AS usages_to_create;
    
    -- Step 1: INSERT missing usages records for component_id = 1 AND 2 only
    -- Optimized: USE NOT EXISTS instead of LEFT JOIN for better performance
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
        qa_bytes
    )
    SELECT 
        aat.user_id,
        c.id AS component_id,
        CASE 
            WHEN c.id = 2 THEN (COALESCE(q.bytes, 0) + 
                                COALESCE(q.cal_bytes, 0) + 
                                COALESCE(q.card_bytes, 0) + 
                                COALESCE(q.file_bytes, 0) + 
                                COALESCE(q.file_common_bytes, 0) + 
                                0 + -- file_chat_bytes (NOT IN quota TABLE)
                                0 + -- file_contact_bytes (NOT IN quota TABLE)
                                COALESCE(q.qa_bytes, 0))
            ELSE 0
        END AS used_value,
        NULL AS used_data,
        pd.description,
        CASE WHEN c.id = 2 THEN COALESCE(q.bytes, 0) ELSE 0 END AS mail_bytes,
        CASE WHEN c.id = 2 THEN COALESCE(q.cal_bytes, 0) ELSE 0 END AS cal_bytes,
        CASE WHEN c.id = 2 THEN COALESCE(q.card_bytes, 0) ELSE 0 END AS card_bytes,
        CASE WHEN c.id = 2 THEN COALESCE(q.file_bytes, 0) ELSE 0 END AS file_note_bytes,
        CASE WHEN c.id = 2 THEN COALESCE(q.file_common_bytes, 0) ELSE 0 END AS file_comment_bytes,
        0 AS file_chat_bytes,
        0 AS file_contact_bytes,
        CASE WHEN c.id = 2 THEN COALESCE(q.qa_bytes, 0) ELSE 0 END AS qa_bytes
    FROM flo_subscription.app_account_token aat
    INNER JOIN flo_subscription.orders o ON aat.user_id = o.user_id
    INNER JOIN flo_subscription.plan_details pd ON o.plan_id = pd.plan_id
    INNER JOIN flo_subscription.components c ON pd.component_id = c.id
    LEFT JOIN preflow_41.user u_old ON aat.user_id = u_old.id
    LEFT JOIN preflow_41.quota q ON u_old.username = q.username
    WHERE c.id IN (2, 3)
    AND NOT EXISTS (
        SELECT 1 
        FROM flo_subscription.usages u 
        WHERE u.user_id = aat.user_id AND u.component_id = c.id
    );
    
    SET pnCreatedCount = ROW_COUNT();
    
    -- Step 2: UPDATE existing usages records WHERE component_id = 2 WITH quota data (only active usages)
    -- Optimized: Replaced EXISTS WITH direct JOIN, removed redundant joins
    UPDATE flo_subscription.usages u
    INNER JOIN flo_subscription.app_account_token aat ON u.user_id = aat.user_id
    INNER JOIN preflow_41.user u_old ON u.user_id = u_old.id
    INNER JOIN preflow_41.quota q ON u_old.username = q.username
    SET 
        u.mail_bytes = q.bytes,
        u.cal_bytes = q.cal_bytes,
        u.card_bytes = q.card_bytes,
        u.file_note_bytes = q.file_bytes,
        u.file_comment_bytes = q.file_common_bytes,
        u.qa_bytes = q.qa_bytes,
        u.used_value = (COALESCE(q.bytes, 0) + 
                        COALESCE(q.cal_bytes, 0) + 
                        COALESCE(q.card_bytes, 0) + 
                        COALESCE(q.file_bytes, 0) + 
                        COALESCE(q.file_common_bytes, 0) + 
                        COALESCE(u.file_chat_bytes, 0) + 
                        COALESCE(u.file_contact_bytes, 0) + 
                        COALESCE(q.qa_bytes, 0)),
        u.updated_date = CURRENT_TIMESTAMP(3)
    WHERE u.component_id = 2
    AND u.is_active = 1;
    
    SET pnQuotaUpdatedCount = ROW_COUNT();
    
    -- SHOW results
    SELECT '=== MIGRATION COMPLETED ===' AS result_header;
    SELECT 
        pnCreatedCount AS usages_created,
        pnQuotaUpdatedCount AS quota_records_updated,
        CASE 
            WHEN pnCreatedCount = pnUsagesToCreate THEN 'ALL usages created successfully'
            ELSE CONCAT('WARNING: Expected ', pnUsagesToCreate, ' but created ', pnCreatedCount)
        END AS status; 
END