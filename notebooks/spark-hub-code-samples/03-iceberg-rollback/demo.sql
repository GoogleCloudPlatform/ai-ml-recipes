-- ============================================================================
-- DEMO 3: DISASTER RECOVERY VIA METADATA ROLLBACK
-- ============================================================================


-- Step 0: Prepare the orders Iceberg table
USE lakehouse_samples;

CREATE OR REPLACE TEMPORARY VIEW raw_orders
USING bigquery
OPTIONS (
  table "bigquery-public-data.thelook_ecommerce.orders"
);

CREATE NAMESPACE IF NOT EXISTS ecommerce;

CREATE OR REPLACE TABLE ecommerce.orion_orders
USING iceberg
AS SELECT * FROM raw_orders;

CREATE OR REPLACE TEMPORARY VIEW raw_bq_order_items
USING bigquery
OPTIONS (
  table "bigquery-public-data.thelook_ecommerce.order_items"
);

CREATE OR REPLACE TABLE ecommerce.orion_order_items
USING iceberg
PARTITIONED BY (status)
AS SELECT * FROM raw_bq_order_items;


-- Step 1: Record baseline state & latest snapshot ID

SELECT 
  snapshot_id AS baseline_snapshot_id, 
  committed_at, 
  summary['operation'] AS operation,
  summary['total-records'] AS total_records
FROM ecommerce.orion_order_items.snapshots
ORDER BY committed_at DESC 
LIMIT 1;

SELECT 
  COUNT(*) AS total_items, 
  COUNT(sale_price) AS non_null_prices,
  ROUND(SUM(sale_price), 2) / 1e6 AS total_revenue 
FROM ecommerce.orion_order_items;

-- Step 2: Simulate realistic production catastrophe
-- CONTEXT: An engineer applies a 20% flash discount intended only for 'Processing' orders.
-- THE BUG: 
-- 1. Omitted the WHERE clause.
-- 2. Forgot "ELSE sale_price" in the CASE statement.
-- RESULT: Orders with status != 'Processing' evaluate to NULL, wiping out historical prices
-- across all other statuses (Complete, Shipped, etc.) in seconds!

UPDATE ecommerce.orion_order_items
SET sale_price = CASE 
  WHEN status = 'Processing' THEN ROUND(sale_price * 0.80, 2)
END;

-- Step 3: Validate catastrophic corruption
-- Thousands of completed orders now have NULL sale_prices, tanking total revenue.
SELECT 
  COUNT(*) AS corrupted_null_records,
  ROUND(SUM(sale_price), 2) AS corrupted_total_revenue
FROM ecommerce.orion_order_items
WHERE status = 'Complete' AND sale_price IS NULL;

-- Step 4: Audit Iceberg metadata manifests to identify pre-incident snapshot

SELECT 
  CAST(snapshot_id AS STRING) AS snapshot_id_str, 
  CAST(parent_id AS STRING) AS parent_id_str, 
  committed_at, 
  summary['operation'] AS op,
  summary['total-records'] AS total_records
FROM ecommerce.orion_order_items.snapshots
ORDER BY committed_at DESC;

-- Step 5: Execute zero-copy instant rollback to parent snapshot
-- Pass the parent_id identified in Step 5 (or the baseline_snapshot_id from Step 2)
CALL system.rollback_to_snapshot(
  table => 'lakehouse_samples.ecommerce.orion_order_items', 
  snapshot_id => 1314150840314849959 -- Replace with actual baseline snapshot_id bigint
);

-- Step 6: Verify instantaneous restoration with zero parquet rewrites
SELECT 
  COUNT(*) AS total_items, 
  COUNT(sale_price) AS valid_prices,
  ROUND(SUM(sale_price), 2) / 1e6 AS restored_total_revenue 
FROM lakehouse_samples.ecommerce.orion_order_items;
