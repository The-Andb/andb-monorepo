CREATE PROCEDURE `OTE_migrateUsagesShareCol_V2`(
    IN psEmail VARCHAR(255)  -- NULL OR empty = migrate ALL users, otherwise migrate SPECIFIC user BY email
)
BEGIN
    DECLARE pnTotalMembers INT DEFAULT 0;
    DECLARE pnTotalRecords INT DEFAULT 0;
    DECLARE pnUpdatedCount INT DEFAULT 0;
    DECLARE pnStep2Count INT DEFAULT 0;
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
    
    -- GET counts (only active records)
    SELECT COUNT(DISTINCT cnm.member_user_id) INTO pnTotalMembers
    FROM preflow_40.collection_notification_member cnm
    INNER JOIN flo_subscription.app_account_token aat ON cnm.member_user_id = aat.user_id
    WHERE cnm.member_user_id IS NOT NULL
    AND cnm.channel_id > 0
    AND cnm.collection_id > 0
    AND cnm.is_active = 1
    AND (pnTargetUserId IS NULL OR cnm.member_user_id = pnTargetUserId);
    
    SELECT COUNT(*) INTO pnTotalRecords
    FROM preflow_40.collection_notification_member cnm
    INNER JOIN flo_subscription.app_account_token aat ON cnm.member_user_id = aat.user_id
    WHERE cnm.member_user_id IS NOT NULL
    AND cnm.channel_id > 0
    AND cnm.collection_id > 0
    AND cnm.is_active = 1
    AND (pnTargetUserId IS NULL OR cnm.member_user_id = pnTargetUserId);
    
    -- SHOW migration info
    SELECT '=== SHARE COLLECTION USAGES MIGRATION STARTED ===' AS header;
    SELECT 
        pnTotalMembers AS total_members_with_records,
        pnTotalRecords AS total_records;
    
    -- Step 1: UPDATE users WITH collection_notification_member records (AS member)
    UPDATE flo_subscription.usages u
    INNER JOIN flo_subscription.components c ON u.component_id = c.id AND c.type = 4
    INNER JOIN (
        SELECT 
            cnm.member_user_id,
            COUNT(DISTINCT cnm.collection_id) AS record_count,
            JSON_ARRAYAGG(
                JSON_OBJECT(
                    'collectionId', cnm.collection_id,
                    'ownerUserId', cnm.owner_user_id
                )
            ) AS used_data_json
        FROM preflow_40.collection_notification_member cnm
        WHERE cnm.member_user_id IS NOT NULL
        AND cnm.channel_id > 0
        AND cnm.collection_id > 0
        AND cnm.is_active = 1
        GROUP BY cnm.member_user_id
    ) AS member_agg ON u.user_id = member_agg.member_user_id
    SET 
        u.used_value = member_agg.record_count,
        u.used_data = member_agg.used_data_json,
        u.updated_date = CURRENT_TIMESTAMP(3)
    WHERE u.is_active = 1
    AND (pnTargetUserId IS NULL OR u.user_id = pnTargetUserId);
    
    SET pnUpdatedCount = ROW_COUNT();
    
    -- Step 2: UPDATE users WITHOUT collection_notification_member records TO 0
    UPDATE flo_subscription.usages u
    INNER JOIN flo_subscription.components c ON u.component_id = c.id AND c.type = 4
    LEFT JOIN (
        SELECT DISTINCT cnm.member_user_id
        FROM preflow_40.collection_notification_member cnm
        WHERE cnm.member_user_id IS NOT NULL
        AND cnm.channel_id > 0
        AND cnm.collection_id > 0
        AND cnm.is_active = 1
    ) AS cnm_exists ON u.user_id = cnm_exists.member_user_id
    SET 
        u.used_value = 0,
        u.used_data = NULL,
        u.updated_date = CURRENT_TIMESTAMP(3)
    WHERE u.is_active = 1
    AND cnm_exists.member_user_id IS NULL
    AND (pnTargetUserId IS NULL OR u.user_id = pnTargetUserId);
    
    SET pnStep2Count = ROW_COUNT();
    
    -- SHOW results
    SELECT '=== MIGRATION COMPLETED ===' AS result_header;
    SELECT 
        pnUpdatedCount AS step1_users_with_shares_updated,
        pnStep2Count AS step2_users_without_shares_updated,
        (pnUpdatedCount + pnStep2Count) AS total_usages_updated;
    
END