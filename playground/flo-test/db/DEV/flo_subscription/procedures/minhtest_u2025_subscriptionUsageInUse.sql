CREATE PROCEDURE `minhtest_u2025_subscriptionUsageInUse`(
    IN pnUserID BIGINT
)
BEGIN
  --
  WITH target_orders AS (
  SELECT o.id
      ,o.plan_id
      ,o.user_id
      ,o.name
      ,o.price
      ,o.period
      ,o.auto_renew
      ,o.description
      ,o.created_date
      ,o.updated_date
    FROM orders o
   WHERE user_id = pnUserID
   ORDER BY is_active DESC, created_date DESC
   LIMIT 1
  )
  SELECT o.id order_id, o.plan_id, o.user_id
    ,o.name plan_name, o.price plan_price, o.period plan_period, o.description plan_description
    ,o.auto_renew, o.created_date order_created_date, o.updated_date order_updated_date
    ,od.component_id, od.component_value, od.description component_description
    ,c.name component_name, c.type component_type, c.unit component_unit
    ,u.used_value,u.used_data, u.created_date usage_created_date, u.updated_date usage_updated_date
    ,p.id purchase_id,p.product_id, p.next_product_id
    ,p.description purchase_description, p.purchase_platform, p.status purchase_status
    ,p.purchase_date, p.expires_at, p.next_renewal_date, p.created_date purchase_created_date, p.updated_date purchase_updated_date
    ,t.transaction_uid, t.original_transaction_uid
    ,CASE
      WHEN p.id IS NOT NULL THEN 'paid'
      ELSE 'free'
    END subscription_type
    ,pl.product_id plan_product_id, pl.order_number plan_order_number
    FROM target_orders o
    JOIN order_details od ON (o.id = od.order_id)
    JOIN components c ON (od.component_id = c.id)
    JOIN plans pl ON (o.plan_id = pl.id)
    LEFT JOIN usages u ON (u.user_id = o.user_id
               AND u.is_active = 1
                 AND u.component_id = c.id
                )
    LEFT JOIN purchases p ON (p.order_id = o.id
                  AND p.user_id = o.user_id
                  AND p.is_current = 1
                 )
    LEFT JOIN transactions t ON (t.id = p.transaction_id);
  --            
END