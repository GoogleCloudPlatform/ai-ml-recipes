{{ config(
    materialized='view'
) }}

SELECT
    order_id,
    user_id,
    TRIM(status)                    AS order_status,
    gender                          AS customer_gender,
    CAST(created_at AS TIMESTAMP)   AS order_timestamp,
    CAST(shipped_at AS TIMESTAMP)   AS shipping_timestamp,
    num_of_item                     AS items_count
FROM ecommerce.bronze_orders
WHERE status != 'Test_Account' -- Filter out internal sandbox test accounts
