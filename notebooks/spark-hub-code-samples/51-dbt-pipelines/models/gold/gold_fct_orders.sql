{{ config(
    materialized='incremental',
    file_format='iceberg',
    incremental_strategy='merge',
    unique_key='order_item_id'
) }}

-- Computes key financial performance metrics per order item incrementally
SELECT
    oi.id                           AS order_item_id,
    oi.order_id                     AS order_id,
    oi.user_id                      AS customer_id,
    o.order_timestamp,
    p.cubesat_subsystem,
    ROUND(oi.sale_price, 2)         AS gross_revenue,
    p.unit_cost,
    ROUND(oi.sale_price - p.unit_cost, 2) AS net_profit_margin
FROM ecommerce.bronze_order_items oi
JOIN {{ ref('sil_orders') }} o ON oi.order_id = o.order_id
JOIN {{ ref('gold_dim_products') }} p ON oi.product_id = p.product_id

{% if is_incremental() %}
  -- Only process new orders loaded since the last pipeline run
  WHERE o.order_timestamp > (SELECT MAX(order_timestamp) FROM {{ this }})
{% endif %}
