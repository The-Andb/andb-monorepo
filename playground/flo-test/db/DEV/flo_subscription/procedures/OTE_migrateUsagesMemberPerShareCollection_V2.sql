CREATE PROCEDURE `OTE_migrateUsagesMemberPerShareCollection_V2`(
    IN psEmail VARCHAR(255)  -- NULL OR empty = migrate ALL users, otherwise migrate SPECIFIC user BY email
)
BEGIN
    DECLARE pnTotalOwners INT DEFAULT 0;
    DECLARE pnTotalMemberRecords INT DEFAULT 0;
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
    SELECT COUNT(DISTINCT cnm.owner_user_id) INTO pnTotalOwners
    FROM preflow_41.collection_notification_member cnm
    INNER JOIN flo_subscription.app_account_token aat ON cnm.owner_user_id = aat.user_id
    WHERE cnm.owner_user_id IS NOT NULL
    AND cnm.channel_id > 0
    AND cnm.collection_id > 0
    AND cnm.is_active = 1
    AND (pnTargetUserId IS NULL OR cnm.owner_user_id = pnTargetUserId);
    
    SELECT COUNT(*) INTO pnTotalMemberRecords
    FROM preflow_41.collection_notification_member cnm
    INNER JOIN flo_subscription.app_account_token aat ON cnm.owner_user_id = aat.user_id
    WHERE cnm.owner_user_id IS NOT NULL
    AND cnm.channel_id > 0
    AND cnm.collection_id > 0
    AND cnm.is_active = 1
    AND (pnTargetUserId IS NULL OR cnm.owner_user_id = pnTargetUserId);
    
    -- SHOW migration info
    SELECT '=== MEMBER PER SHARE USAGES MIGRATION STARTED ===' AS header;
    SELECT 
        pnTotalOwners AS total_owners_with_members,
        pnTotalMemberRecords AS total_member_records;
    
    -- Step 1: UPDATE users WITH collection_notification_member records (AS owner)
    UPDATE flo_subscription.usages u
    INNER JOIN flo_subscription.components c ON u.component_id = c.id AND c.type = 5
    INNER JOIN (
        SELECT 
            collection_agg.owner_user_id,
            MAX(collection_agg.member_count) AS max_member_count,
            JSON_ARRAYAGG(
                JSON_OBJECT(
                    'memberCount', collection_agg.member_count,
                    'collectionId', collection_agg.collection_id
                )
            ) AS used_data_json
        FROM (
            SELECT 
                cnm.owner_user_id,
                cnm.collection_id,
                COUNT(DISTINCT cnm.member_user_id) AS member_count
            FROM preflow_41.collection_notification_member cnm
            WHERE cnm.owner_user_id IS NOT NULL
            AND cnm.channel_id > 0
            AND cnm.collection_id > 0
            AND cnm.is_active = 1
            GROUP BY cnm.owner_user_id, cnm.collection_id
        ) AS collection_agg
        GROUP BY collection_agg.owner_user_id
    ) AS owner_agg ON u.user_id = owner_agg.owner_user_id
    SET 
        u.used_value = owner_agg.max_member_count,
        u.used_data = owner_agg.used_data_json,
        u.updated_date = CURRENT_TIMESTAMP(3)
    WHERE u.is_active = 1
    AND (pnTargetUserId IS NULL OR u.user_id = pnTargetUserId);
    
    SET pnUpdatedCount = ROW_COUNT();
    
    -- Step 2: UPDATE users WITHOUT collection_notification_member records (AS owner) TO 0
    UPDATE flo_subscription.usages u
    INNER JOIN flo_subscription.components c ON u.component_id = c.id AND c.type = 5
    LEFT JOIN (
        SELECT DISTINCT cnm.owner_user_id
        FROM preflow_41.collection_notification_member cnm
        WHERE cnm.owner_user_id IS NOT NULL
        AND cnm.channel_id > 0
        AND cnm.collection_id > 0
        AND cnm.is_active = 1
    ) AS cnm_exists ON u.user_id = cnm_exists.owner_user_id
    SET 
        u.used_value = 0,
        u.used_data = NULL,
        u.updated_date = CURRENT_TIMESTAMP(3)
    WHERE u.is_active = 1
    AND cnm_exists.owner_user_id IS NULL
    AND (pnTargetUserId IS NULL OR u.user_id = pnTargetUserId);
    
    SET pnStep2Count = ROW_COUNT();
    
    -- SHOW results
    SELECT '=== MIGRATION COMPLETED ===' AS result_header;
    SELECT 
        pnUpdatedCount AS step1_users_with_members_updated,
        pnStep2Count AS step2_users_without_members_updated,
        (pnUpdatedCount + pnStep2Count) AS total_usages_updated;
    
END