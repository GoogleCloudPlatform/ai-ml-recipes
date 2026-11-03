-- Ensure unit economics are sound and we aren't selling parts at a loss
SELECT
    order_item_id,
    gross_revenue,
    unit_cost,
    net_profit_margin
FROM {{ ref('gold_fct_orders') }}
WHERE net_profit_margin < 0.00
