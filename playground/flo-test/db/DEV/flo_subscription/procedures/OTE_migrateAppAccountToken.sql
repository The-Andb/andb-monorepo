CREATE PROCEDURE `OTE_migrateAppAccountToken`()
BEGIN
    DECLARE pnNewCount INT DEFAULT 0;
    DECLARE pnUpdateCount INT DEFAULT 0;
    
    -- Count users that need new migration
    SELECT COUNT(*) INTO pnNewCount
    FROM preflow_41.user u
    LEFT JOIN flo_subscription.app_account_token aat ON u.id = aat.user_id
    WHERE aat.user_id IS NULL;
    
    -- Count users that need email UPDATE
    SELECT COUNT(*) INTO pnUpdateCount
    FROM preflow_41.user u
    INNER JOIN flo_subscription.app_account_token aat ON u.id = aat.user_id
    WHERE aat.email = "";
    
    -- SHOW counts
    SELECT CONCAT('Users needing new migration: ', pnNewCount) AS new_migration_info;
    SELECT CONCAT('Users needing email UPDATE: ', pnUpdateCount) AS update_info;
    
    -- Step 1: UPDATE existing records WITH NULL email
    UPDATE flo_subscription.app_account_token aat
    INNER JOIN preflow_41.user u ON aat.user_id = u.id
    SET aat.email = u.email,
        aat.updated_date = NOW()
    WHERE aat.email = "";
    
    -- SHOW UPDATE result
    SELECT CONCAT('Updated ', ROW_COUNT(), ' records WITH email') AS update_result;
    
    -- Step 2: Migrate new users
    INSERT INTO flo_subscription.app_account_token (
        user_id,
        token,
        email,
        gateway_id
    )
    SELECT 
        u.id,
        UUID(),
        u.email,
        1
    FROM preflow_41.user u
    LEFT JOIN flo_subscription.app_account_token aat ON u.id = aat.user_id
    WHERE aat.user_id IS NULL;
    
    -- SHOW migration result
    SELECT CONCAT('Migrated ', ROW_COUNT(), ' new users') AS migration_result;
    
    -- SHOW sample of migrated records
    SELECT 
        user_id,
        token,
        email,
        gateway_id,
        created_date
    FROM flo_subscription.app_account_token 
    ORDER BY created_date DESC 
    LIMIT 5;
    
END