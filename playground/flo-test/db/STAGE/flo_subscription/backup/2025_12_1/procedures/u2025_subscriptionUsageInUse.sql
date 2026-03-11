CREATE PROCEDURE `u2025_subscriptionUsageInUse`(
  pnUserID BIGINT(20)
,pvEmail VARCHAR(100))
BEGIN
  --
  DECLARE nThisYear INT(4) DEFAULT year(now());
  --
  SELECT o.id, u.id, o.id AS order_id, o.plan_id, o.user_id, o.name AS plan_name, o.price AS plan_price, o.period AS plan_period, o.auto_renew
        ,o.description AS plan_description, o.created_date AS order_created_date, o.updated_date AS order_updated_date
        ,od.component_id, od.component_value, od.description AS component_description
        ,c.name AS component_name, c.type AS component_type, c.unit AS component_unit
        ,COALESCE(SUM(u.used_value), 0) AS used_value
        ,JSON_ARRAYAGG(u.used_data) AS used_data_agg
        -- Purchase data (NULL for free plans)
        ,p.id AS purchase_id, p.product_id, p.description AS purchase_description, p.purchase_platform, p.status AS purchase_status, p.purchase_date
        ,p.expires_at, p.next_renewal_date, p.created_date AS purchase_created_date, p.updated_date AS purchase_updated_date
        -- Transaction data (NULL for free plans)
        ,t.transaction_uid, t.original_transaction_uid
        -- Determine subscription type
        ,CASE
            WHEN p.id IS NOT NULL THEN 'paid'
            ELSE 'free'
          END AS subscription_type
     FROM orders o
     JOIN order_details od ON (o.id = od.order_id)
     JOIN components c ON (od.component_id = c.id)
     JOIN usages u ON (u.user_id = o.user_id AND u.is_active = 1 AND u.component_id = c.id AND u.created_year = nThisYear)
LEFT JOIN purchases p ON (p.order_id = o.id AND p.user_id = o.user_id AND p.is_current = 1 AND p.created_year = nThisYear)
LEFT JOIN transactions t ON (t.id = p.transaction_id AND t.created_year = nThisYear)
    WHERE o.user_id = pnUserID
      AND o.is_active = 1
    GROUP BY o.id, c.id, p.id
    ORDER BY o.created_date DESC, c.id
    LIMIT 1000;
  --
END