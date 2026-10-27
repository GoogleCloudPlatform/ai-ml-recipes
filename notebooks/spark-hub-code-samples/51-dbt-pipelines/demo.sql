-- ============================================================================
-- DEMO 51: DBT PIPELINES ON MANAGED SPARK
-- ============================================================================


-- Step 0: Prepare the production orders & raw Black Friday Iceberg tables
CREATE OR REPLACE TEMPORARY VIEW raw_orders
USING bigquery
OPTIONS (
  table "bigquery-public-data.thelook_ecommerce.orders"
);

USE lakehouse_samples;

CREATE NAMESPACE IF NOT EXISTS ecommerce;

CREATE TABLE IF NOT EXISTS ecommerce.orion_orders
USING iceberg
AS SELECT * FROM raw_orders WHERE created_at < '2023-11-01';

CREATE TABLE IF NOT EXISTS ecommerce.raw_blackfriday_orders
USING iceberg
AS SELECT * FROM raw_orders WHERE created_at >= '2023-11-01' AND created_at < '2023-12-01';

-- Step 1: Staging dbt model — standardize raw Black Friday promotional orders
-- File: models/staging/stg_blackfriday_orders.sql (materialized='view')
SELECT
    CAST(order_id AS INT)           AS order_id,
    TRIM(username)                  AS username,
    TRIM(status)                    AS status,
    CAST(order_quantity AS INT)     AS order_quantity,
    CAST(created_at AS TIMESTAMP)   AS created_at
FROM ecommerce.raw_blackfriday_orders
WHERE created_at >= '2023-11-01'
  AND created_at <  '2023-12-01';

-- Step 2: Incremental dbt model — merge validated records into main Iceberg table
-- File: models/marts/orion_orders.sql (materialized='incremental', incremental_strategy='merge', unique_key='order_id')
SELECT
    order_id,
    username,
    status,
    order_quantity,
    created_at
FROM ecommerce.stg_blackfriday_orders
WHERE created_at > (SELECT MAX(created_at) FROM ecommerce.orion_orders);

-- Step 3: Automated dbt data quality audit gates
-- File: tests/assert_valid_order_quantity.sql (+ unique, not_null, accepted_values in models/schema.yml)
SELECT
    order_id,
    username,
    order_quantity
FROM ecommerce.stg_blackfriday_orders
WHERE order_quantity <= 0
   OR order_quantity IS NULL;

-- Step 4: Execute staging model, quality audits, and Iceberg MERGE in a single command
-- Terminal: dbt build --select +orion_orders
MERGE INTO ecommerce.orion_orders AS target
USING ecommerce.stg_blackfriday_orders AS source
ON target.order_id = source.order_id
WHEN MATCHED THEN UPDATE SET *
WHEN NOT MATCHED THEN INSERT *;

-- Step 5: Confirm all Black Friday promotional orders are live in production
-- File: verify_orders.sql
USE lakehouse_samples;

SELECT 
    'production_orion_orders' AS target_table,
    COUNT(*) AS total_production_orders,
    COUNT_IF(created_at >= '2023-11-01') AS merged_blackfriday_orders
FROM ecommerce.orion_orders;
