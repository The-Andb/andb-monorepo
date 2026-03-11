CREATE PROCEDURE `OTE_migrateOrderDetails`()
BEGIN
    DECLARE pnOrdersWithoutDetails INT DEFAULT 0;
    DECLARE pnTotalOrderDetailsToCreate INT DEFAULT 0;
    DECLARE pnCreatedCount INT DEFAULT 0;
    
    -- Count orders that don't have order_details
    SELECT COUNT(*) INTO pnOrdersWithoutDetails
    FROM flo_subscription.orders o
    LEFT JOIN flo_subscription.order_details od ON o.id = od.order_id
    WHERE od.order_id IS NULL;
    
    -- Count total order_details that will be created
    SELECT COUNT(*) INTO pnTotalOrderDetailsToCreate
    FROM flo_subscription.orders o
    INNER JOIN flo_subscription.plan_details pd ON o.plan_id = pd.plan_id
    LEFT JOIN flo_subscription.order_details od ON o.id = od.order_id
    WHERE od.order_id IS NULL;
    
    -- SHOW migration info
    SELECT '=== ORDER DETAILS MIGRATION STARTED ===' AS header;
    SELECT 
        pnOrdersWithoutDetails AS orders_missing_details,
        pnTotalOrderDetailsToCreate AS order_details_to_create;
    
    -- Migrate plan_details TO order_details
    INSERT INTO flo_subscription.order_details (
        order_id,
        component_id,
        component_value,
        description
    )
    SELECT 
        o.id AS order_id,
        pd.component_id,
        pd.component_value,
        pd.description
    FROM flo_subscription.orders o
    INNER JOIN flo_subscription.plan_details pd ON o.plan_id = pd.plan_id
    LEFT JOIN flo_subscription.order_details od ON o.id = od.order_id
    WHERE od.order_id IS NULL;
    
    SET pnCreatedCount = ROW_COUNT();
    
    -- SHOW results
    SELECT '=== MIGRATION COMPLETED ===' AS result_header;
    SELECT 
        pnCreatedCount AS order_details_created,
        pnOrdersWithoutDetails AS orders_processed,
        CASE 
            WHEN pnCreatedCount = pnTotalOrderDetailsToCreate THEN 'ALL order_details created successfully'
            ELSE CONCAT('WARNING: Expected ', pnTotalOrderDetailsToCreate, ' but created ', pnCreatedCount)
        END AS status;
    
    -- SHOW sample of created order_details
    SELECT '=== Sample of created order_details ===' AS sample_header;
    SELECT 
        od.id AS order_detail_id,
        od.order_id,
        od.component_id,
        od.component_value,
        od.description,
        c.name AS component_name,
        c.type AS component_type,
        c.unit AS component_unit
    FROM flo_subscription.order_details od
    INNER JOIN flo_subscription.components c ON od.component_id = c.id
    ORDER BY od.created_date DESC 
    LIMIT 5;
    
END