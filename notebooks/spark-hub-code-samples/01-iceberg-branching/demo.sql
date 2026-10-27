-- ============================================================================
-- DEMO 1: WRITE-AUDIT-PUBLISH (WAP) VIA ICEBERG BRANCHING
-- ============================================================================


-- Step 0: Prepare the orders Iceberg table
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

-- Step 1: Ingest black Friday promo orders
CREATE OR REPLACE TEMPORARY VIEW promo_orders
USING bigquery
OPTIONS (
  table "bigquery-public-data.thelook_ecommerce.orders",
  filter "created_at >= '2023-11-01' AND created_at < '2023-12-01'"
);

-- Step 2: Create an isolated audit branch for the new batch
USE lakehouse_samples;

ALTER TABLE ecommerce.orion_orders 
CREATE BRANCH blackfriday_promo;

-- Step 3: Insert new batch records directly into the branch
INSERT INTO ecommerce.orion_orders.branch_blackfriday_promo
SELECT * FROM promo_orders;

-- Step 4: Prove data isolation between main and the audit branch
-- Production queries do not see the new records yet:
SELECT 'production_main' AS target, COUNT(*) AS record_count 
FROM ecommerce.orion_orders
UNION ALL
SELECT 'blackfriday_branch' AS target, COUNT(*) AS record_count 
FROM ecommerce.orion_orders.branch_blackfriday_promo;

-- Step 5: Run data quality audit gates on the branch
SELECT 
  COUNT_IF(user_id IS NULL) AS null_users,
  COUNT_IF(num_of_item <= 0) AS invalid_quantities,
  COUNT_IF(status NOT IN ('Complete', 'Processing', 'Shipped', 'Cancelled', 'Returned')) AS invalid_statuses
FROM ecommerce.orion_orders.branch_blackfriday_promo;

-- Step 6: Atomic Fast-Forward into production
CALL lakehouse_samples.system.fast_forward(
  table => 'lakehouse_samples.ecommerce.orion_orders',
  branch => 'main',
  to => 'blackfriday_promo'
);


SELECT 'production_main' AS target, COUNT(*) AS record_count 
FROM ecommerce.orion_orders;

-- Step 7: Clean up branch metadata
ALTER TABLE ecommerce.orion_orders DROP BRANCH blackfriday_promo;
