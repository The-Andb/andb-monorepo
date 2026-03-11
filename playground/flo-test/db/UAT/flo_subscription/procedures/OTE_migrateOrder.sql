CREATE PROCEDURE `OTE_migrateOrder`()
BEGIN
    DECLARE pnCount INT DEFAULT 0;
    DECLARE pnMigratedCount INT DEFAULT 0;
    DECLARE pnUnmatchedCount INT DEFAULT 0;
    DECLARE pnDefaultPlanCount INT DEFAULT 0;
    DECLARE pnDefaultPlanMigratedCount INT DEFAULT 0;
    
    -- Count subscription_purchase records WITH is_current = 1 AND user_id NOT IN orders
    SELECT COUNT(*) INTO pnCount
    FROM preflow_41.subscription_purchase sp
    LEFT JOIN flo_subscription.orders o ON sp.user_id = o.user_id
    WHERE sp.is_current = 1 AND o.user_id IS NULL;
    
    -- Count how many can be matched WITH plans
    SELECT COUNT(*) INTO pnMigratedCount
    FROM preflow_41.subscription_purchase sp
    INNER JOIN flo_subscription.plans p ON sp.sub_id = p.product_id
    INNER JOIN preflow_41.subscription s ON sp.sub_id = s.id
    LEFT JOIN flo_subscription.orders o ON sp.user_id = o.user_id
    WHERE sp.is_current = 1 AND o.user_id IS NULL;
    
    SET pnUnmatchedCount = pnCount - pnMigratedCount;
    
    -- Count users who don't have subscription_purchase records AND don't have orders
    -- AND must exist IN flo_subscription.app_account_token
    SELECT COUNT(*) INTO pnDefaultPlanCount
    FROM preflow_41.user u
    LEFT JOIN preflow_41.subscription_purchase sp ON u.id = sp.user_id AND sp.is_current = 1
    LEFT JOIN flo_subscription.orders o ON u.id = o.user_id
    INNER JOIN flo_subscription.app_account_token aat ON u.id = aat.user_id
    WHERE sp.user_id IS NULL AND o.user_id IS NULL;
    
    -- SHOW migration info
    SELECT '=== SUBSCRIPTION MIGRATION STARTED ===' AS header;
    SELECT 
        pnCount AS total_subscription_purchases_eligible,
        pnMigratedCount AS will_be_migrated_from_subscription_purchase,
        pnUnmatchedCount AS will_be_skipped_from_subscription_purchase,
        pnDefaultPlanCount AS users_to_get_default_plan;
    
    -- Migrate subscription_purchase TO orders
    INSERT INTO flo_subscription.orders (
        plan_id,
        user_id,
        is_active,
        name,
        price,
        period,
        auto_renew,
        description,
        subs_type,
        order_number
    )
    SELECT 
        p.id AS plan_id,
        sp.user_id,
        1 AS is_active,  -- SET AS active
        p.name,
        p.price,
        p.period,
        p.auto_renew,
        COALESCE(sp.description, p.description) AS description,  -- USE subscription description OR plan description
        s.subs_type,  -- USE subs_type FROM preflow_41.subscription TABLE
        p.order_number
    FROM preflow_41.subscription_purchase sp
    INNER JOIN flo_subscription.plans p ON sp.sub_id = p.product_id
    INNER JOIN preflow_41.subscription s ON sp.sub_id = s.id
    LEFT JOIN flo_subscription.orders o ON sp.user_id = o.user_id
    WHERE sp.is_current = 1 AND o.user_id IS NULL;
    
    SET pnMigratedCount = ROW_COUNT();
    
    -- Migrate users without subscription_purchase records TO DEFAULT plan
    INSERT INTO flo_subscription.orders (
        plan_id,
        user_id,
        is_active,
        name,
        price,
        period,
        auto_renew,
        description,
        subs_type,
        order_number
    )
    SELECT 
        p.id AS plan_id,
        u.id AS user_id,
        1 AS is_active,  -- SET AS active
        p.name,
        p.price,
        p.period,
        p.auto_renew,
        p.description,
        0 AS subs_type,  -- DEFAULT subs_type for users without subscription
        p.order_number
    FROM preflow_41.user u
    LEFT JOIN preflow_41.subscription_purchase sp ON u.id = sp.user_id AND sp.is_current = 1
    LEFT JOIN flo_subscription.orders o ON u.id = o.user_id
    INNER JOIN flo_subscription.plans p ON p.product_id = 'ea0f0fa86f3320eac0a8155a4cc0b8e563dd'
    INNER JOIN flo_subscription.app_account_token aat ON u.id = aat.user_id
    WHERE sp.user_id IS NULL AND o.user_id IS NULL;
    
    SET pnDefaultPlanMigratedCount = ROW_COUNT();
    
    -- SHOW results
    SELECT '=== MIGRATION COMPLETED ===' AS result_header;
    SELECT 
        pnMigratedCount AS records_migrated_from_subscription_purchase,
        pnUnmatchedCount AS records_skipped_from_subscription_purchase,
        pnDefaultPlanMigratedCount AS records_migrated_to_default_plan,
        CASE 
            WHEN pnUnmatchedCount > 0 THEN CONCAT('WARNING: ', pnUnmatchedCount, ' records skipped due TO no matching plan')
            ELSE 'ALL records migrated successfully'
        END AS status;
    
    -- SHOW sample of migrated records
    SELECT '=== Sample of migrated records ===' AS sample_header;
    SELECT 
        o.id AS order_id,
        o.plan_id,
        o.user_id,
        o.name,
        o.price,
        o.period,
        o.auto_renew,
        o.created_date
    FROM flo_subscription.orders o
    ORDER BY o.created_date DESC 
    LIMIT 5;
    
END