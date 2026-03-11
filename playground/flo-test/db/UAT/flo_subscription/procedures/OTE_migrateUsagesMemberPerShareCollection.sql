CREATE PROCEDURE `OTE_migrateUsagesMemberPerShareCollection`()
BEGIN
    DECLARE pnTotalOwners INT DEFAULT 0;
    DECLARE pnTotalMemberRecords INT DEFAULT 0;
    DECLARE pnUsagesToCreate INT DEFAULT 0;
    DECLARE pnCreatedCount INT DEFAULT 0;
    DECLARE pnUpdatedCount INT DEFAULT 0;
    DECLARE pnBatchSize INT DEFAULT 2000;
    DECLARE pnProcessed INT DEFAULT 0;
    DECLARE pnRowsAffected INT DEFAULT 0;
    
    -- GET counts (only active records)
    SELECT COUNT(DISTINCT cnm.owner_user_id) INTO pnTotalOwners
    FROM preflow_41.collection_notification_member cnm
    INNER JOIN flo_subscription.app_account_token aat ON cnm.owner_user_id = aat.user_id
    WHERE cnm.owner_user_id IS NOT NULL
    AND cnm.channel_id > 0
    AND cnm.collection_id > 0
    AND cnm.is_active = 1;
    
    SELECT COUNT(*) INTO pnTotalMemberRecords
    FROM preflow_41.collection_notification_member cnm
    INNER JOIN flo_subscription.app_account_token aat ON cnm.owner_user_id = aat.user_id
    WHERE cnm.owner_user_id IS NOT NULL
    AND cnm.channel_id > 0
    AND cnm.collection_id > 0
    AND cnm.is_active = 1;
    
    SELECT COUNT(*) INTO pnUsagesToCreate
    FROM (
        SELECT DISTINCT cnm.owner_user_id
        FROM preflow_41.collection_notification_member cnm
        INNER JOIN flo_subscription.app_account_token aat ON cnm.owner_user_id = aat.user_id
        WHERE cnm.owner_user_id IS NOT NULL
        AND cnm.channel_id > 0
        AND cnm.collection_id > 0
        AND cnm.is_active = 1
        AND NOT EXISTS (
            SELECT 1 
            FROM flo_subscription.usages u 
            WHERE u.user_id = cnm.owner_user_id AND u.component_id = 5
        )
    ) AS missing_owners;
    
    -- SHOW migration info
    SELECT '=== MEMBER PER SHARE USAGES MIGRATION STARTED ===' AS header;
    SELECT 
        pnTotalOwners AS total_owners_with_members,
        pnTotalMemberRecords AS total_member_records,
        pnUsagesToCreate AS usages_to_create,
        pnBatchSize AS batch_size;
    
    -- Process owners IN batches USING a more efficient approach
    batch_loop: WHILE pnProcessed < pnTotalOwners DO
        -- Step 1: UPDATE existing records IN this batch
        UPDATE flo_subscription.usages u
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
                INNER JOIN flo_subscription.app_account_token aat ON cnm.owner_user_id = aat.user_id
                INNER JOIN (
                    SELECT DISTINCT cnm2.owner_user_id
                    FROM preflow_41.collection_notification_member cnm2
                    INNER JOIN flo_subscription.app_account_token aat2 ON cnm2.owner_user_id = aat2.user_id
                    WHERE cnm2.owner_user_id IS NOT NULL
                    AND cnm2.channel_id > 0
                    AND cnm2.collection_id > 0
                    AND cnm2.is_active = 1
                    ORDER BY cnm2.owner_user_id
                    LIMIT pnBatchSize OFFSET pnProcessed
                ) AS batch_owners ON cnm.owner_user_id = batch_owners.owner_user_id
                WHERE cnm.owner_user_id IS NOT NULL
                AND cnm.channel_id > 0
                AND cnm.collection_id > 0
                AND cnm.is_active = 1
                GROUP BY cnm.owner_user_id, cnm.collection_id
            ) AS collection_agg
            GROUP BY collection_agg.owner_user_id
        ) AS owner_agg ON u.user_id = owner_agg.owner_user_id AND u.component_id = 5
        SET 
            u.used_value = owner_agg.max_member_count,
            u.used_data = owner_agg.used_data_json,
            u.is_active = 1,
            u.updated_date = CURRENT_TIMESTAMP(3)
        WHERE u.is_active = 1;
        
        SET pnUpdatedCount = pnUpdatedCount + ROW_COUNT();
        
        -- Step 2: INSERT new records that don't exist
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
            owner_agg.owner_user_id AS user_id,
            5 AS component_id,
            owner_agg.max_member_count AS used_value,
            owner_agg.used_data_json AS used_data,
            CONCAT('Migrated FROM collection_notification_member: max ', owner_agg.max_member_count, ' member(s) across ', owner_agg.collection_count, ' collection(s)') AS description,
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
                collection_agg.owner_user_id,
                COUNT(DISTINCT collection_agg.collection_id) AS collection_count,
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
                INNER JOIN flo_subscription.app_account_token aat ON cnm.owner_user_id = aat.user_id
                INNER JOIN (
                    SELECT DISTINCT cnm2.owner_user_id
                    FROM preflow_41.collection_notification_member cnm2
                    INNER JOIN flo_subscription.app_account_token aat2 ON cnm2.owner_user_id = aat2.user_id
                    WHERE cnm2.owner_user_id IS NOT NULL
                    AND cnm2.channel_id > 0
                    AND cnm2.collection_id > 0
                    AND cnm2.is_active = 1
                    ORDER BY cnm2.owner_user_id
                    LIMIT pnBatchSize OFFSET pnProcessed
                ) AS batch_owners ON cnm.owner_user_id = batch_owners.owner_user_id
                WHERE cnm.owner_user_id IS NOT NULL
                AND cnm.channel_id > 0
                AND cnm.collection_id > 0
                AND cnm.is_active = 1
                GROUP BY cnm.owner_user_id, cnm.collection_id
            ) AS collection_agg
            GROUP BY collection_agg.owner_user_id
        ) AS owner_agg
        WHERE NOT EXISTS (
            SELECT 1 
            FROM flo_subscription.usages u 
            WHERE u.user_id = owner_agg.owner_user_id AND u.component_id = 5
        );
        
        SET pnCreatedCount = pnCreatedCount + ROW_COUNT();
        SET pnProcessed = pnProcessed + pnBatchSize;
        
    END WHILE batch_loop;
    
    -- SHOW results
    SELECT '=== MIGRATION COMPLETED ===' AS result_header;
    SELECT 
        pnCreatedCount AS usages_created,
        pnUpdatedCount AS usages_updated,
        pnTotalMemberRecords AS total_member_records_migrated,
        CASE 
            WHEN pnCreatedCount = pnUsagesToCreate THEN 'ALL usages created successfully'
            ELSE CONCAT('WARNING: Expected ', pnUsagesToCreate, ' but created ', pnCreatedCount)
        END AS status;
    
END