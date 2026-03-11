CREATE PROCEDURE `OTE_migratePurchases`()
BEGIN
    DECLARE pnTotalOrders INT DEFAULT 0;
    DECLARE pnActiveOrders INT DEFAULT 0;
    DECLARE pnMigratedCount INT DEFAULT 0;
    DECLARE pnExistingPurchases INT DEFAULT 0;
    
    -- Count orders
    SELECT COUNT(*) INTO pnTotalOrders FROM flo_subscription.orders;
    SELECT COUNT(*) INTO pnActiveOrders 
    FROM flo_subscription.orders o 
    INNER JOIN flo_subscription.app_account_token aat ON o.user_id = aat.user_id 
    WHERE o.is_active = 1;
    SELECT COUNT(*) INTO pnExistingPurchases FROM flo_subscription.purchases;
    
    -- SHOW migration info
    SELECT '=== ORDERS TO PURCHASES MIGRATION STARTED ===' AS header;
    SELECT 
        pnTotalOrders AS total_orders,
        pnActiveOrders AS active_orders_to_migrate,
        pnExistingPurchases AS existing_purchases;
    
    -- Migrate orders TO purchases
    INSERT INTO flo_subscription.purchases (
        user_id,
        order_id,
        description,
        transaction_id,
        is_current,
        purchase_platform,
        product_id,
        status,
        purchase_date,
        grace_period_at,
        expires_at,
        last_renewal_date,
        next_renewal_date,
        last_transaction_id
    )
    SELECT 
        o.user_id,
        o.id AS order_id,
        COALESCE(p.description, '') AS description,
        0 AS transaction_id,  -- DEFAULT transaction_id
        1 AS is_current,    -- SET AS current
        4 AS purchase_platform,  -- Admin SET instead of buy
        p.product_id,
        1 AS status,         -- Active status
        o.created_date AS purchase_date,
        CASE 
            WHEN p.product_id = 'ea0f0fa86f3320eac0a8155a4cc0b8e563dd' THEN NULL
            ELSE DATE_ADD(o.created_date, INTERVAL o.period DAY)
        END AS grace_period_at,
        CASE 
            WHEN p.product_id = 'ea0f0fa86f3320eac0a8155a4cc0b8e563dd' THEN NULL
            ELSE DATE_ADD(o.created_date, INTERVAL o.period DAY)
        END AS expires_at,
        o.created_date AS last_renewal_date,
        CASE 
            WHEN p.product_id = 'ea0f0fa86f3320eac0a8155a4cc0b8e563dd' THEN NULL
            WHEN o.auto_renew = 1 THEN DATE_ADD(o.created_date, INTERVAL o.period DAY)
            ELSE NULL
        END AS next_renewal_date,
        NULL AS last_transaction_id
    FROM flo_subscription.orders o
    INNER JOIN flo_subscription.plans p ON o.plan_id = p.id
    INNER JOIN flo_subscription.app_account_token aat ON o.user_id = aat.user_id
    WHERE o.is_active = 1;
    
    SET pnMigratedCount = ROW_COUNT();
    
    -- SHOW results
    SELECT '=== MIGRATION COMPLETED ===' AS result_header;
    SELECT 
        pnMigratedCount AS purchases_created,
        pnExistingPurchases AS purchases_existed_before,
        CASE 
            WHEN pnExistingPurchases > 0 THEN CONCAT('WARNING: ', pnExistingPurchases, ' purchases already existed')
            ELSE 'ALL orders migrated successfully'
        END AS status;
    
    -- SHOW sample of migrated purchases
    SELECT '=== Sample of migrated purchases ===' AS sample_header;
    SELECT 
        pu.id AS purchase_id,
        pu.user_id,
        pu.order_id,
        pu.product_id,
        pu.status,
        pu.is_current,
        pu.purchase_date,
        pu.grace_period_at,
        pu.expires_at,
        pu.next_renewal_date
    FROM flo_subscription.purchases pu
    ORDER BY pu.created_date DESC 
    LIMIT 5;
    
END