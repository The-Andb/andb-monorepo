CREATE PROCEDURE `OTE_migrateUsagesShareCol`()
BEGIN
    DECLARE pnTotalMembers INT DEFAULT 0;
    DECLARE pnTotalRecords INT DEFAULT 0;
    DECLARE pnUsagesToCreate INT DEFAULT 0;
    DECLARE pnCreatedCount INT DEFAULT 0;
    DECLARE pnUpdatedCount INT DEFAULT 0;
    DECLARE pnBatchSize INT DEFAULT 2000;
    DECLARE pnProcessed INT DEFAULT 0;
    
    -- GET counts (only active records)
    SELECT COUNT(DISTINCT cnm.member_user_id) INTO pnTotalMembers
    FROM preflow_41.collection_notification_member cnm
    INNER JOIN flo_subscription.app_account_token aat ON cnm.member_user_id = aat.user_id
    WHERE cnm.member_user_id IS NOT NULL
    AND cnm.channel_id > 0
    AND cnm.collection_id > 0
    AND cnm.is_active = 1;
    
    SELECT COUNT(*) INTO pnTotalRecords
    FROM preflow_41.collection_notification_member cnm
    INNER JOIN flo_subscription.app_account_token aat ON cnm.member_user_id = aat.user_id
    WHERE cnm.member_user_id IS NOT NULL
    AND cnm.channel_id > 0
    AND cnm.collection_id > 0
    AND cnm.is_active = 1;
    
    SELECT COUNT(*) INTO pnUsagesToCreate
    FROM (
        SELECT DISTINCT cnm.member_user_id
        FROM preflow_41.collection_notification_member cnm
        INNER JOIN flo_subscription.app_account_token aat ON cnm.member_user_id = aat.user_id
        WHERE cnm.member_user_id IS NOT NULL
        AND cnm.channel_id > 0
        AND cnm.collection_id > 0
        AND cnm.is_active = 1
        AND NOT EXISTS (
            SELECT 1 
            FROM flo_subscription.usages u 
            WHERE u.user_id = cnm.member_user_id AND u.component_id = 4
        )
    ) AS missing_members;
    
    -- SHOW migration info
    SELECT '=== SHARE COLLECTION USAGES MIGRATION STARTED ===' AS header;
    SELECT 
        pnTotalMembers AS total_members_with_records,
        pnTotalRecords AS total_records,
        pnUsagesToCreate AS usages_to_create,
        pnBatchSize AS batch_size;
    
    -- Process members IN batches TO improve performance
    batch_loop: WHILE pnProcessed < pnTotalMembers DO
        -- Step 1: UPDATE existing records IN this batch (only active usages)
        UPDATE flo_subscription.usages u
        INNER JOIN (
            SELECT 
                cnm.member_user_id,
                COUNT(cnm.id) AS record_count
            FROM preflow_41.collection_notification_member cnm
            INNER JOIN flo_subscription.app_account_token aat ON cnm.member_user_id = aat.user_id
            INNER JOIN (
                SELECT DISTINCT cnm2.member_user_id
                FROM preflow_41.collection_notification_member cnm2
                INNER JOIN flo_subscription.app_account_token aat2 ON cnm2.member_user_id = aat2.user_id
                WHERE cnm2.member_user_id IS NOT NULL
                AND cnm2.channel_id > 0
                AND cnm2.collection_id > 0
                AND cnm2.is_active = 1
                ORDER BY cnm2.member_user_id
                LIMIT pnBatchSize OFFSET pnProcessed
            ) AS batch_members ON cnm.member_user_id = batch_members.member_user_id
            WHERE cnm.member_user_id IS NOT NULL
            AND cnm.channel_id > 0
            AND cnm.collection_id > 0
            AND cnm.is_active = 1
            GROUP BY cnm.member_user_id
        ) AS member_agg ON u.user_id = member_agg.member_user_id AND u.component_id = 4
        SET 
            u.used_value = member_agg.record_count,
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
            member_agg.member_user_id AS user_id,
            4 AS component_id,
            member_agg.record_count AS used_value,
            NULL AS used_data,
            CONCAT('Migrated FROM collection_notification_member: ', member_agg.record_count, ' record(s)') AS description,
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
                cnm.member_user_id,
                COUNT(cnm.id) AS record_count
            FROM preflow_41.collection_notification_member cnm
            INNER JOIN flo_subscription.app_account_token aat ON cnm.member_user_id = aat.user_id
            INNER JOIN (
                SELECT DISTINCT cnm2.member_user_id
                FROM preflow_41.collection_notification_member cnm2
                INNER JOIN flo_subscription.app_account_token aat2 ON cnm2.member_user_id = aat2.user_id
                WHERE cnm2.member_user_id IS NOT NULL
                AND cnm2.channel_id > 0
                AND cnm2.collection_id > 0
                AND cnm2.is_active = 1
                ORDER BY cnm2.member_user_id
                LIMIT pnBatchSize OFFSET pnProcessed
            ) AS batch_members ON cnm.member_user_id = batch_members.member_user_id
            WHERE cnm.member_user_id IS NOT NULL
            AND cnm.channel_id > 0
            AND cnm.collection_id > 0
            AND cnm.is_active = 1
            GROUP BY cnm.member_user_id
        ) AS member_agg
        WHERE NOT EXISTS (
            SELECT 1 
            FROM flo_subscription.usages u 
            WHERE u.user_id = member_agg.member_user_id AND u.component_id = 4
        );
        
        SET pnCreatedCount = pnCreatedCount + ROW_COUNT();
        SET pnProcessed = pnProcessed + pnBatchSize;
        
    END WHILE batch_loop;
    
    -- SHOW results
    SELECT '=== MIGRATION COMPLETED ===' AS result_header;
    SELECT 
        pnCreatedCount AS usages_created,
        pnUpdatedCount AS usages_updated,
        pnTotalRecords AS total_records_migrated,
        CASE 
            WHEN pnCreatedCount = pnUsagesToCreate THEN 'ALL usages created successfully'
            ELSE CONCAT('WARNING: Expected ', pnUsagesToCreate, ' but created ', pnCreatedCount)
        END AS status;
    
END