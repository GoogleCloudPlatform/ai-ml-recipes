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
-- File: models/silver/sil_orders.sql (materialized='view')


-- ============================================================================
-- 3. GOLD LAYER: Business-Level Dimensions & Incremental Facts
-- ============================================================================

-- File: models/gold/gold_dim_products.sql (materialized='table')
-- File: models/gold/gold_fct_orders.sql (materialized='incremental', unique_key='order_item_id')


-- ============================================================================
-- 4. AUTOMATED DATA QUALITY AUDITS (Gold Quality Gatekeeper)
-- ============================================================================

-- File: tests/assert_positive_profit_margin.sql


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
