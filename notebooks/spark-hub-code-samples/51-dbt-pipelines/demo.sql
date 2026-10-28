-- ============================================================================
-- DEMO 51: THREE-TIER MEDALLION PIPELINES ON MANAGED SERVERLESS SPARK
-- ============================================================================

-- ============================================================================
-- 1. BRONZE LAYER: Raw Ingestion Tables (Untrusted Source Material)
-- ============================================================================
CREATE NAMESPACE IF NOT EXISTS ecommerce;

CREATE OR REPLACE TABLE ecommerce.bronze_orders USING iceberg AS 
SELECT * FROM `bigquery-public-data.thelook_ecommerce.orders`;

CREATE OR REPLACE TABLE ecommerce.bronze_order_items USING iceberg AS 
SELECT * FROM `bigquery-public-data.thelook_ecommerce.order_items`;

CREATE OR REPLACE TABLE ecommerce.bronze_products USING iceberg AS 
SELECT * FROM `bigquery-public-data.thelook_ecommerce.products`;


-- ============================================================================
-- 2. SILVER LAYER: Cleaned & Standardized Views
-- ============================================================================

-- File: models/silver/sil_products.sql (materialized='view')
SELECT
    id                              AS product_id,
    TRIM(name)                      AS product_name,
    TRIM(category)                  AS raw_category,
    ROUND(retail_price, 2)          AS retail_price,
    ROUND(cost, 2)                  AS unit_cost,
    TRIM(brand)                     AS brand
FROM ecommerce.bronze_products;


-- File: models/silver/sil_orders.sql (materialized='view')
SELECT
    order_id,
    user_id,
    TRIM(status)                    AS order_status,
    gender                          AS customer_gender,
    CAST(created_at AS TIMESTAMP)   AS order_timestamp,
    CAST(shipped_at AS TIMESTAMP)   AS shipping_timestamp,
    num_of_item                     AS items_count
FROM ecommerce.bronze_orders
WHERE status != 'Test_Account'; -- Filter out internal sandbox test accounts


-- ============================================================================
-- 3. GOLD LAYER: Business-Level Dimensions & Incremental Facts
-- ============================================================================

-- File: models/gold/gold_dim_products.sql (materialized='table')
-- Maps e-commerce categories directly to Orionis DIY CubeSat Subsystems
SELECT
    product_id,
    product_name,
    brand,
    retail_price,
    unit_cost,
    CASE 
        WHEN raw_category IN ('Active', 'Outerwear', 'Sweaters') THEN 'EPS (Electrical Power Systems)'
        WHEN raw_category IN ('Jeans', 'Pants', 'Shorts') THEN 'ADCS (Attitude Determination & Control)'
        WHEN raw_category IN ('Accessories', 'Swim') THEN 'OBDH (On-Board Data Handling)'
        WHEN raw_category IN ('Underwear', 'Sleepwear') THEN 'Structure & Thermal'
        ELSE 'Payload & Scientific Instrumentation'
    END AS cubesat_subsystem
FROM {{ ref('sil_products') }};


-- File: models/gold/gold_fct_orders.sql (materialized='incremental', unique_key='order_item_id')
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
{% endif %};


-- ============================================================================
-- 4. AUTOMATED DATA QUALITY AUDITS (Gold Quality Gatekeeper)
-- ============================================================================

-- File: tests/assert_positive_profit_margin.sql
-- Ensure unit economics are sound and we aren't selling parts at a loss
SELECT
    order_item_id,
    gross_revenue,
    unit_cost,
    net_profit_margin
FROM {{ ref('gold_fct_orders') }}
WHERE net_profit_margin < 0.00;


-- ============================================================================
-- 5. RUNTIME COMMAND & BUSINESS INTELLIGENCE VERIFICATION
-- ============================================================================

-- Terminal command to execute the pipeline:
-- dbt build

-- Behind the scenes, Managed Serverless Spark executes this high-speed Iceberg MERGE:
-- MERGE INTO ecommerce.gold_fct_orders AS target
-- USING temp_incremental_gold_fct_orders AS source
-- ON target.order_item_id = source.order_item_id
-- WHEN MATCHED THEN UPDATE SET *
-- WHEN NOT MATCHED THEN INSERT *;


-- Verify results & fetch business metrics:
SELECT
    cubesat_subsystem,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(gross_revenue), 2) AS total_revenue_usd,
    ROUND(AVG(net_profit_margin), 2) AS avg_item_margin_usd
FROM ecommerce.gold_fct_orders
GROUP BY cubesat_subsystem
ORDER BY total_revenue_usd DESC;
