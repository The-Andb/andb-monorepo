CREATE PROCEDURE `u2026_migrateEmailToUsages`(
    IN psEmail VARCHAR(255)
)
BEGIN
    DECLARE pnTotalUsers INT DEFAULT 0;
    DECLARE pnQuotaUpdatedCount INT DEFAULT 0;
    DECLARE pnCalendarUpdatedCount INT DEFAULT 0;
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
    SELECT 
        COUNT(DISTINCT aat.user_id) INTO pnTotalUsers 
    FROM flo_subscription.app_account_token aat
    WHERE (pnTargetUserId IS NULL OR aat.user_id = pnTargetUserId);
    
    -- SHOW migration info
    SELECT '=== USAGES STORAGE MIGRATION STARTED ===' AS header;
    SELECT pnTotalUsers AS total_users;
    
    -- Step 1: UPDATE quota data (single UPDATE - faster for most datasets)
    UPDATE flo_subscription.usages u
    INNER JOIN flo_subscription.components c ON u.component_id = c.id AND c.type = 2
    INNER JOIN flo_subscription.app_account_token aat ON u.user_id = aat.user_id
    INNER JOIN preflow_41.user u_old ON u.user_id = u_old.id
    INNER JOIN preflow_41.quota q ON u_old.username = q.username
    SET 
        u.mail_bytes = COALESCE(q.bytes, 0),
        u.email_count = COALESCE(q.messages, 0),
        u.used_value = (COALESCE(q.bytes, 0) + 
                        COALESCE(u.cal_bytes, 0) + 
                        COALESCE(u.card_bytes, 0) + 
                        COALESCE(u.file_comment_bytes, 0) + 
                        COALESCE(u.file_chat_bytes, 0) + 
                        COALESCE(u.file_note_bytes, 0) + 
                        COALESCE(u.file_contact_bytes, 0) + 
                        COALESCE(u.qa_bytes, 0)),
        u.updated_date = CURRENT_TIMESTAMP(3)
    WHERE u.is_active = 1
    AND (pnTargetUserId IS NULL OR u.user_id = pnTargetUserId);
    
    SET pnQuotaUpdatedCount = ROW_COUNT();
    
    -- SHOW results
    SELECT '=== MIGRATION COMPLETED ===' AS result_header;
    SELECT 
        pnQuotaUpdatedCount AS quota_records_updated,
        pnCalendarUpdatedCount AS calendar_bytes_updated; 
END