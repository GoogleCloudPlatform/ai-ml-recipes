{{ config(
    materialized='view'
) }}

SELECT
    id                              AS product_id,
    TRIM(name)                      AS product_name,
    TRIM(category)                  AS raw_category,
    ROUND(retail_price, 2)          AS retail_price,
    ROUND(cost, 2)                  AS unit_cost,
    TRIM(brand)                     AS brand
FROM ecommerce.bronze_products
WHERE id IS NOT NULL
  AND name IS NOT NULL
  AND category IS NOT NULL

