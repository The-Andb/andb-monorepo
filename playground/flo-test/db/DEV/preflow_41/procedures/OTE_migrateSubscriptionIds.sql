CREATE PROCEDURE `OTE_migrateSubscriptionIds`( )
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- Start transaction
    START TRANSACTION;

    -- =====================================================
    -- SUBSCRIPTION TABLE MIGRATION (FIRST)
    -- =====================================================
    
    SELECT '=== SUBSCRIPTION TABLE (FIRST) ===' AS section;
    
    -- SHOW current records BEFORE migration
    SELECT 
        'BEFORE MIGRATION' AS status,
        id,
        name,
        price,
        period,
        subs_type,
        order_number
    FROM subscription 
    WHERE id IN (
        'com.floware.flo.product.monthlypremium',
        'com.floware.flo.product.monthlypro',
        'com.floware.flo.product.yearlypremium',
        'com.floware.flo.product.yearlypro'
    )
    ORDER BY id;

    -- Migration 1: monthlypremium -> monthlystandard
    UPDATE subscription 
    SET id = 'com.floware.flo.qc.product.monthlystandard', price = 0.99
    WHERE id = 'com.floware.flo.product.monthlypremium';

    -- Migration 2: monthlypro -> monthlypremium
    UPDATE subscription 
    SET id = 'com.floware.flo.qc.product.monthlypremium', price = 4.99
    WHERE id = 'com.floware.flo.product.monthlypro';

    -- Migration 3: yearlypremium -> yearlystandard
    UPDATE subscription 
    SET id = 'com.floware.flo.qc.product.yearlystandard', price = 9.99
    WHERE id = 'com.floware.flo.product.yearlypremium';

    -- Migration 4: yearlypro -> yearlypremium
    UPDATE subscription 
    SET id = 'com.floware.flo.qc.product.yearlypremium', price = 49.99
    WHERE id = 'com.floware.flo.product.yearlypro';

    -- SHOW results after migration
    SELECT 
        'AFTER MIGRATION' AS status,
        id,
        name,
        price,
        period,
        subs_type,
        order_number
    FROM subscription 
    WHERE id IN (
        'com.floware.flo.qc.product.monthlystandard',
        'com.floware.flo.qc.product.monthlypremium',
        'com.floware.flo.qc.product.yearlystandard',
        'com.floware.flo.qc.product.yearlypremium'
    )
    ORDER BY id;

    -- Verify no old IDs remain IN subscription TABLE
    SELECT 
        'REMAINING OLD IDs' AS status,
        id,
        name,
        price,
        period,
        subs_type,
        order_number
    FROM subscription 
    WHERE id IN (
        'com.floware.flo.product.monthlypremium',
        'com.floware.flo.product.monthlypro',
        'com.floware.flo.product.yearlypremium',
        'com.floware.flo.product.yearlypro'
    )
    ORDER BY id;

    -- =====================================================
    -- SUBSCRIPTION_PURCHASE TABLE MIGRATION (SECOND)
    -- =====================================================
    
    SELECT '=== SUBSCRIPTION_PURCHASE TABLE (SECOND) ===' AS section;
    
    -- SHOW current counts BEFORE migration
    SELECT 
        'BEFORE MIGRATION' AS status,
        sub_id,
        COUNT(*) AS count
    FROM subscription_purchase 
    WHERE sub_id IN (
        'com.floware.flo.product.monthlypremium',
        'com.floware.flo.product.monthlypro',
        'com.floware.flo.product.yearlypremium',
        'com.floware.flo.product.yearlypro'
    )
    GROUP BY sub_id
    ORDER BY sub_id;

    -- Migration 1: monthlypremium -> monthlystandard
    UPDATE subscription_purchase 
    SET sub_id = 'com.floware.flo.qc.product.monthlystandard'
    WHERE sub_id = 'com.floware.flo.product.monthlypremium';

    -- Migration 2: monthlypro -> monthlypremium
    UPDATE subscription_purchase 
    SET sub_id = 'com.floware.flo.qc.product.monthlypremium'
    WHERE sub_id = 'com.floware.flo.product.monthlypro';

    -- Migration 3: yearlypremium -> yearlystandard
    UPDATE subscription_purchase 
    SET sub_id = 'com.floware.flo.qc.product.yearlystandard'
    WHERE sub_id = 'com.floware.flo.product.yearlypremium';

    -- Migration 4: yearlypro -> yearlypremium
    UPDATE subscription_purchase 
    SET sub_id = 'com.floware.flo.qc.product.yearlypremium'
    WHERE sub_id = 'com.floware.flo.product.yearlypro';

    -- SHOW results after migration
    SELECT 
        'AFTER MIGRATION' AS status,
        sub_id,
        COUNT(*) AS count
    FROM subscription_purchase 
    WHERE sub_id IN (
        'com.floware.flo.qc.product.monthlystandard',
        'com.floware.flo.qc.product.monthlypremium',
        'com.floware.flo.qc.product.yearlystandard',
        'com.floware.flo.qc.product.yearlypremium'
    )
    GROUP BY sub_id
    ORDER BY sub_id;

    -- Verify no old IDs remain IN subscription_purchase
    SELECT 
        'REMAINING OLD IDs' AS status,
        sub_id,
        COUNT(*) AS count
    FROM subscription_purchase 
    WHERE sub_id IN (
        'com.floware.flo.product.monthlypremium',
        'com.floware.flo.product.monthlypro',
        'com.floware.flo.product.yearlypremium',
        'com.floware.flo.product.yearlypro'
    )
    GROUP BY sub_id;

    -- =====================================================
    -- SUBSCRIPTION_DETAIL TABLE MIGRATION (THIRD)
    -- =====================================================
    
    SELECT '=== SUBSCRIPTION_DETAIL TABLE (THIRD) ===' AS section;
    
    -- Migration 1: monthlypremium -> monthlystandard
    UPDATE subscription_detail 
    SET sub_id = 'com.floware.flo.qc.product.monthlystandard'
    WHERE sub_id = 'com.floware.flo.product.monthlypremium';

    -- Migration 2: monthlypro -> monthlypremium
    UPDATE subscription_detail 
    SET sub_id = 'com.floware.flo.qc.product.monthlypremium'
    WHERE sub_id = 'com.floware.flo.product.monthlypro';

    -- Migration 3: yearlypremium -> yearlystandard
    UPDATE subscription_detail 
    SET sub_id = 'com.floware.flo.qc.product.yearlystandard'
    WHERE sub_id = 'com.floware.flo.product.yearlypremium';

    -- Migration 4: yearlypro -> yearlypremium
    UPDATE subscription_detail 
    SET sub_id = 'com.floware.flo.qc.product.yearlypremium'
    WHERE sub_id = 'com.floware.flo.product.yearlypro';


    -- =====================================================
    -- SUBSCRIPTION_DETAIL DESCRIPTION UPDATES
    -- =====================================================

    -- UPDATE descriptions for migrated subscription IDs
    UPDATE subscription_detail 
    SET description = 'Storage 5 GB'
    WHERE sub_id = 'ea0f0fa86f3320eac0a8155a4cc0b8e563dd' AND com_id = 1;

    UPDATE subscription_detail 
    SET description = 'One 3rd account'
    WHERE sub_id = 'ea0f0fa86f3320eac0a8155a4cc0b8e563dd' AND com_id = 2;

    UPDATE subscription_detail 
    SET description = 'One month, three 3rd accounts'
    WHERE sub_id = 'com.floware.flo.qc.product.monthlystandard' AND com_id = 2;

    UPDATE subscription_detail 
    SET description = 'Storage 10 GB, one month'
    WHERE sub_id = 'com.floware.flo.qc.product.monthlystandard' AND com_id = 1;

    UPDATE subscription_detail 
    SET description = 'Storage 10GB, one year'
    WHERE sub_id = 'com.floware.flo.qc.product.yearlystandard' AND com_id = 1;

    UPDATE subscription_detail 
    SET description = 'One year, three 3rd accounts'
    WHERE sub_id = 'com.floware.flo.qc.product.yearlystandard' AND com_id = 2;

    UPDATE subscription_detail 
    SET description = 'Storage 100 GB, one month'
    WHERE sub_id = 'com.floware.flo.qc.product.monthlypremium' AND com_id = 1;

    UPDATE subscription_detail 
    SET description = 'Unlimit 3rd account'
    WHERE sub_id = 'com.floware.flo.qc.product.monthlypremium' AND com_id = 2;

    UPDATE subscription_detail 
    SET description = 'Storage 100 GB, one year'
    WHERE sub_id = 'com.floware.flo.qc.product.yearlypremium' AND com_id = 1;

    UPDATE subscription_detail 
    SET description = 'Unlimit 3rd account'
    WHERE sub_id = 'com.floware.flo.qc.product.yearlypremium' AND com_id = 2;

    UPDATE subscription_detail 
    SET description = 'One month, features'
    WHERE sub_id = 'com.floware.flo.qc.product.monthlystandard' AND com_id = 3;

    -- =====================================================
    -- ADMIN_PROMOTION TABLE UPDATES
    -- =====================================================
    
    SELECT '=== ADMIN_PROMOTION TABLE ===' AS section;
    
    UPDATE admin_promotion 
    SET signup_type = 'com.floware.flo.qc.product.yearlypremium'
    WHERE id = 1;

    UPDATE admin_promotion 
    SET signup_type = 'ea0f0fa86f3320eac0a8155a4cc0b8e563dd'
    WHERE id = 2;

    -- Commit the transaction
    COMMIT;

    SELECT 'ALL subscription ID migrations completed successfully!' AS result;
END