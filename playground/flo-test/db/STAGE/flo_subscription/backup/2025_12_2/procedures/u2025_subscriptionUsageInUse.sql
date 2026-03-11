CREATE PROCEDURE `u2025_subscriptionUsageInUse`(
    IN pnUserID BIGINT
)
BEGIN
    WITH target_orders AS (
        SELECT *
        FROM (
            SELECT *
            FROM orders
            WHERE user_id = pnUserID
            ORDER BY is_active DESC, created_date DESC
            LIMIT 1
        ) AS t
    )
    SELECT 
        o.id AS order_id,
        o.plan_id,
        o.user_id,
        o.name AS plan_name,
        o.price AS plan_price,
        o.period AS plan_period,
        o.auto_renew,
        o.description AS plan_description,
        o.created_date AS order_created_date,
        o.updated_date AS order_updated_date,
        od.component_id,
        od.component_value,
        od.description AS component_description,
        c.name AS component_name,
        c.type AS component_type,
        c.unit AS component_unit,
        u.used_value,
        u.used_data,
        u.created_date AS usage_created_date,
        u.updated_date AS usage_updated_date,
        p.id AS purchase_id,
        p.product_id,
        p.next_product_id,
        p.description AS purchase_description,
        p.purchase_platform,
        p.status AS purchase_status,
        p.purchase_date,
        p.expires_at,
        p.next_renewal_date,
        p.created_date AS purchase_created_date,
        p.updated_date AS purchase_updated_date,
        t.transaction_uid,
        t.original_transaction_uid,
        a_reach.limit_at AS reach_limit_at,
        a_exceed.limit_at AS exceed_limit_at,
        CASE
            WHEN p.id IS NOT NULL THEN 'paid'
            ELSE 'free'
        END AS subscription_type,
        pl.product_id AS plan_product_id,
        pl.order_number AS plan_order_number
    FROM target_orders o
    JOIN order_details od ON o.id = od.order_id
    JOIN components c ON od.component_id = c.id
    JOIN plans pl ON o.plan_id = pl.id
    LEFT JOIN usages u 
        ON u.user_id = o.user_id
       AND u.is_active = 1
       AND u.component_id = c.id
    LEFT JOIN purchases p 
        ON p.order_id = o.id
       AND p.user_id = o.user_id
       AND p.is_current = 1
    LEFT JOIN transactions t ON t.id = p.transaction_id
    LEFT JOIN alert a_reach 
        ON a_reach.user_id = o.user_id
       AND a_reach.component_id = c.id
       AND a_reach.limit_type = 'REACH'
       AND a_reach.deleted_at IS NULL
    LEFT JOIN alert a_exceed 
        ON a_exceed.user_id = o.user_id
       AND a_exceed.component_id = c.id
       AND a_exceed.limit_type = 'EXCEED'
       AND a_exceed.deleted_at IS NULL;
END