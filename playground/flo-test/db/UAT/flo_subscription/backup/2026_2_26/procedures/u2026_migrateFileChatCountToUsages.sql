CREATE PROCEDURE `u2026_migrateFileChatCountToUsages`(
    IN pnUserId BIGINT,  -- NULL = migrate ALL users, otherwise filter BY SPECIFIC user_id
    IN pnCase INT
)
BEGIN
    DECLARE pnTotalUsers INT DEFAULT 0;
    DECLARE pnUpdatedCount INT DEFAULT 0;
    DECLARE pnBatchSize INT DEFAULT 2000;
    DECLARE pnMinUserId BIGINT DEFAULT 0;
    DECLARE pnMaxUserId BIGINT DEFAULT 0;
    DECLARE pnCurrentMinId BIGINT DEFAULT 0;
    DECLARE pnCurrentMaxId BIGINT DEFAULT 0;
    DECLARE pnIteration INT DEFAULT 0;
    DECLARE pnRowsAffected INT DEFAULT 0;
    
    -- GET total users that have chat file data
    IF pnUserId IS NULL THEN
        SELECT COUNT(DISTINCT user_id) INTO pnTotalUsers
        FROM (
            -- CASE 1: Channel has NO collection > 0 (only collection_id = 0 IN CNM), USE linked_by
            SELECT DISTINCT aat.user_id
            FROM flo_subscription.app_account_token aat
            INNER JOIN preflow_41.storage_file_linked_collection sflc ON sflc.linked_by = aat.email
            WHERE sflc.collection_type = 'CONFERENCE'
              AND NOT EXISTS (
                SELECT 1 FROM preflow_41.collection_notification_member cnm 
                WHERE cnm.channel_id = sflc.collection_id 
                  AND cnm.collection_id > 0
              )
            UNION
            -- CASE 2: collection_id > 0, USE owner_user_id
            SELECT DISTINCT cnm.owner_user_id
            FROM preflow_41.collection_notification_member cnm
            INNER JOIN preflow_41.storage_file_linked_collection sflc ON sflc.collection_id = cnm.channel_id
            WHERE cnm.collection_id > 0
              AND cnm.owner_user_id IS NOT NULL
              AND sflc.collection_type = 'CONFERENCE'
        ) users;
        
        -- GET min/max user_id for pagination
        SELECT MIN(u.user_id), MAX(u.user_id) INTO pnMinUserId, pnMaxUserId
        FROM flo_subscription.usages u
        WHERE u.is_active = 1
          AND u.user_id IN (
            SELECT DISTINCT user_id
            FROM (
                SELECT DISTINCT aat.user_id
                FROM flo_subscription.app_account_token aat
                INNER JOIN preflow_41.storage_file_linked_collection sflc ON sflc.linked_by = aat.email
                WHERE sflc.collection_type = 'CONFERENCE'
                  AND NOT EXISTS (
                    SELECT 1 FROM preflow_41.collection_notification_member cnm 
                    WHERE cnm.channel_id = sflc.collection_id 
                      AND cnm.collection_id > 0
                  )
                UNION
                SELECT DISTINCT cnm.owner_user_id
                FROM preflow_41.collection_notification_member cnm
                INNER JOIN preflow_41.storage_file_linked_collection sflc ON sflc.collection_id = cnm.channel_id
                WHERE cnm.collection_id > 0
                  AND cnm.owner_user_id IS NOT NULL
                  AND sflc.collection_type = 'CONFERENCE'
            ) users
          );
    ELSE
        SELECT COUNT(DISTINCT user_id) INTO pnTotalUsers
        FROM (
            -- CASE 1: Channel has NO collection > 0 (only collection_id = 0 IN CNM), USE linked_by
            SELECT DISTINCT aat.user_id
            FROM flo_subscription.app_account_token aat
            INNER JOIN preflow_41.storage_file_linked_collection sflc ON sflc.linked_by = aat.email
            WHERE sflc.collection_type = 'CONFERENCE'
              AND aat.user_id = pnUserId
              AND NOT EXISTS (
                SELECT 1 FROM preflow_41.collection_notification_member cnm 
                WHERE cnm.channel_id = sflc.collection_id 
                  AND cnm.collection_id > 0
              )
            UNION
            -- CASE 2: collection_id > 0, USE owner_user_id
            SELECT DISTINCT cnm.owner_user_id
            FROM preflow_41.collection_notification_member cnm
            INNER JOIN preflow_41.storage_file_linked_collection sflc ON sflc.collection_id = cnm.channel_id
            WHERE cnm.collection_id > 0
              AND cnm.owner_user_id = pnUserId
              AND cnm.owner_user_id IS NOT NULL
              AND sflc.collection_type = 'CONFERENCE'
        ) users;
        
        -- GET min/max user_id for pagination (filtered BY user_id)
        SELECT MIN(u.user_id), MAX(u.user_id) INTO pnMinUserId, pnMaxUserId
        FROM flo_subscription.usages u
        WHERE u.is_active = 1
          AND u.user_id = pnUserId;
    END IF;
    
    SET pnMinUserId = IFNULL(pnMinUserId, 0);
    SET pnMaxUserId = IFNULL(pnMaxUserId, 0);
    SET pnCurrentMinId = pnMinUserId;
    
    -- SHOW migration info
    SELECT '=== FILE CHAT COUNT TO USAGES MIGRATION V2 STARTED ===' AS header;
    SELECT 
        pnTotalUsers AS total_users_with_chat_files,
        pnMinUserId AS min_user_id,
        pnMaxUserId AS max_user_id,
        pnBatchSize AS batch_size,
        IFNULL(pnUserId, 'ALL') AS filter_user_id,
        CONCAT('CASE ', pnCase) AS migration_case;
    
    -- Early EXIT IF no records TO process
    IF pnMaxUserId = 0 OR pnTotalUsers = 0 THEN
        SELECT '=== NO RECORDS TO UPDATE ===' AS result_header;
        SELECT 0 AS records_updated, 0 AS batches_processed, 'No records found' AS status;
    ELSE
        -- INITIALIZATION STEP: Reset file_chat_count TO 0 for ALL target users (for CASE 1)
        IF pnCase = 1 THEN
            SELECT '=== INITIALIZATION: Resetting file_chat_count AND file_chat_bytes TO 0 ====' AS init_header;
            UPDATE flo_subscription.usages u
            INNER JOIN flo_subscription.components c ON u.component_id = c.id
            SET u.file_chat_count = 0,
                u.file_chat_bytes = 0
            WHERE u.is_active = 1
              AND c.type = 2
              AND (pnUserId IS NULL OR u.user_id = pnUserId);
            
            SELECT ROW_COUNT() AS users_reset;
        END IF;
        
        -- Process IN ID-based batches
    WHILE pnCurrentMinId <= pnMaxUserId DO
        SET pnIteration = pnIteration + 1;
        SET pnCurrentMaxId = pnCurrentMinId + pnBatchSize - 1;
        
        -- UPDATE usages WITH file chat counts
        -- First, UPDATE CASE 1 (files FROM users who linked via email) - REPLACE mode
        IF pnUserId IS NULL THEN
            IF pnCase = 1 THEN
            UPDATE flo_subscription.usages u
            LEFT JOIN (
                SELECT 
                    aat.user_id AS uid,
                    COALESCE(COUNT(DISTINCT sflc.file_uid), 0) AS file_chat_count,
                    COALESCE(SUM(DISTINCT sf.size), 0) AS file_chat_bytes
                FROM flo_subscription.app_account_token aat
                LEFT JOIN preflow_41.storage_file_linked_collection sflc ON sflc.linked_by = aat.email
                  AND sflc.collection_type = 'CONFERENCE'
                  AND NOT EXISTS (
                    SELECT 1 FROM preflow_41.collection_notification_member cnm 
                    WHERE cnm.channel_id = sflc.collection_id 
                      AND cnm.collection_id > 0
                  )
                LEFT JOIN preflow_41.storage_file sf ON CAST(sflc.file_uid AS CHAR CHARACTER SET utf8mb4) COLLATE utf8mb4_general_ci = sf.uid
                WHERE aat.user_id BETWEEN pnCurrentMinId AND pnCurrentMaxId
                  AND sf.uid IS NOT NULL
                GROUP BY aat.user_id
            ) case1_data ON u.user_id = case1_data.uid
            INNER JOIN flo_subscription.components c ON u.component_id = c.id
            SET 
                u.file_chat_count = COALESCE(case1_data.file_chat_count, 0),
                u.file_chat_bytes = COALESCE(case1_data.file_chat_bytes, 0),
                u.updated_date = NOW(3)
            WHERE u.user_id BETWEEN pnCurrentMinId AND pnCurrentMaxId
              AND u.is_active = 1
              AND c.type = 2;  -- STORAGE component type
            END IF;
              
            -- THEN, UPDATE CASE 2 (files FROM collection owners) - ADD mode
            IF pnCase = 2 THEN
            UPDATE flo_subscription.usages u
            INNER JOIN (
                SELECT 
                    cnm.owner_user_id AS uid,
                    COALESCE(COUNT(DISTINCT sflc.file_uid), 0) AS file_chat_count,
                    COALESCE(SUM(DISTINCT sf.size), 0) AS file_chat_bytes
                FROM preflow_41.collection_notification_member cnm
                INNER JOIN preflow_41.storage_file_linked_collection sflc ON sflc.collection_id = cnm.channel_id
                INNER JOIN preflow_41.storage_file sf ON CAST(sflc.file_uid AS CHAR CHARACTER SET utf8mb4) COLLATE utf8mb4_general_ci = sf.uid
                WHERE cnm.owner_user_id BETWEEN pnCurrentMinId AND pnCurrentMaxId
                  AND cnm.collection_id > 0
                  AND cnm.owner_user_id IS NOT NULL
                  AND sflc.collection_type = 'CONFERENCE'
                  AND sf.uid IS NOT NULL
                GROUP BY cnm.owner_user_id
            ) case2_data ON u.user_id = case2_data.uid
            INNER JOIN flo_subscription.components c ON u.component_id = c.id
            SET 
                u.file_chat_count = COALESCE(u.file_chat_count, 0) + case2_data.file_chat_count,
                u.file_chat_bytes = COALESCE(u.file_chat_bytes, 0) + case2_data.file_chat_bytes,
                u.updated_date = NOW(3)
            WHERE u.user_id BETWEEN pnCurrentMinId AND pnCurrentMaxId
              AND u.is_active = 1
              AND c.type = 2;  -- STORAGE component type
            END IF;
        ELSE
            IF pnCase = 1 THEN
            UPDATE flo_subscription.usages u
            LEFT JOIN (
                SELECT 
                    aat.user_id AS uid,
                    COALESCE(COUNT(DISTINCT sflc.file_uid), 0) AS file_chat_count,
                    COALESCE(SUM(DISTINCT sf.size), 0) AS file_chat_bytes
                FROM flo_subscription.app_account_token aat
                LEFT JOIN preflow_41.storage_file_linked_collection sflc ON sflc.linked_by = aat.email
                  AND sflc.collection_type = 'CONFERENCE'
                  AND NOT EXISTS (
                    SELECT 1 FROM preflow_41.collection_notification_member cnm 
                    WHERE cnm.channel_id = sflc.collection_id 
                      AND cnm.collection_id > 0
                  )
                LEFT JOIN preflow_41.storage_file sf ON CAST(sflc.file_uid AS CHAR CHARACTER SET utf8mb4) COLLATE utf8mb4_general_ci = sf.uid
                WHERE aat.user_id BETWEEN pnCurrentMinId AND pnCurrentMaxId
                  AND aat.user_id = pnUserId
                  AND sf.uid IS NOT NULL
                GROUP BY aat.user_id
            ) case1_data ON u.user_id = case1_data.uid
            INNER JOIN flo_subscription.components c ON u.component_id = c.id
            SET 
                u.file_chat_count = COALESCE(case1_data.file_chat_count, 0),
                u.file_chat_bytes = COALESCE(case1_data.file_chat_bytes, 0),
                u.updated_date = NOW(3)
            WHERE u.user_id BETWEEN pnCurrentMinId AND pnCurrentMaxId
              AND u.is_active = 1
              AND c.type = 2;  -- STORAGE component type
            END IF;
              
            -- THEN, UPDATE CASE 2 (files FROM collection owners) - ADD TO existing count
            IF pnCase = 2 THEN
            UPDATE flo_subscription.usages u
            INNER JOIN (
                SELECT 
                    cnm.owner_user_id AS uid,
                    COALESCE(COUNT(DISTINCT sflc.file_uid), 0) AS file_chat_count,
                    COALESCE(SUM(DISTINCT sf.size), 0) AS file_chat_bytes
                FROM preflow_41.collection_notification_member cnm
                INNER JOIN preflow_41.storage_file_linked_collection sflc ON sflc.collection_id = cnm.channel_id
                INNER JOIN preflow_41.storage_file sf ON CAST(sflc.file_uid AS CHAR CHARACTER SET utf8mb4) COLLATE utf8mb4_general_ci = sf.uid
                WHERE cnm.owner_user_id BETWEEN pnCurrentMinId AND pnCurrentMaxId
                  AND cnm.owner_user_id = pnUserId
                  AND cnm.collection_id > 0
                  AND cnm.owner_user_id IS NOT NULL
                  AND sflc.collection_type = 'CONFERENCE'
                  AND sf.uid IS NOT NULL
                GROUP BY cnm.owner_user_id
            ) case2_data ON u.user_id = case2_data.uid
            INNER JOIN flo_subscription.components c ON u.component_id = c.id
            SET 
                u.file_chat_count = COALESCE(u.file_chat_count, 0) + case2_data.file_chat_count,
                u.file_chat_bytes = COALESCE(u.file_chat_bytes, 0) + case2_data.file_chat_bytes,
                u.updated_date = NOW(3)
            WHERE u.user_id BETWEEN pnCurrentMinId AND pnCurrentMaxId
              AND u.is_active = 1
              AND c.type = 2;  -- STORAGE component type
            END IF;
        END IF;
        
        SET pnRowsAffected = ROW_COUNT();
        SET pnUpdatedCount = pnUpdatedCount + pnRowsAffected;
        
        -- Progress output (every 10 batches OR WHEN rows affected)
        IF pnIteration MOD 10 = 0 OR pnRowsAffected > 0 THEN
            SELECT CONCAT('Batch ', pnIteration, ' (user_id ', pnCurrentMinId, '-', pnCurrentMaxId, '): Updated ', pnRowsAffected, '. Total: ', pnUpdatedCount) AS progress;
        END IF;
        
        -- Move TO next batch
        SET pnCurrentMinId = pnCurrentMaxId + 1;
        
    END WHILE;
    
    -- Final summary
    SELECT '=== MIGRATION COMPLETED ===' AS result_header;
    SELECT 
        pnUpdatedCount AS records_updated,
        pnIteration AS batches_processed,
        CASE 
            WHEN pnUpdatedCount > 0 THEN CONCAT('Updated ', pnUpdatedCount, ' USAGE records WITH file chat counts')
            ELSE 'No records updated'
        END AS status;
    END IF;
    
END