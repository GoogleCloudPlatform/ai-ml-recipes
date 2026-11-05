-- ============================================================================
-- 1. BRONZE LAYER: Raw Ingestion Tables (Untrusted Source Material)
-- ============================================================================
USE lakehouse_samples;

CREATE NAMESPACE IF NOT EXISTS ecommerce;

CREATE OR REPLACE TABLE ecommerce.bronze_orders USING iceberg AS 
SELECT * FROM `bigquery-public-data.thelook_ecommerce.orders`;

CREATE OR REPLACE TABLE ecommerce.bronze_order_items USING iceberg AS 
SELECT * FROM `bigquery-public-data.thelook_ecommerce.order_items`;

CREATE OR REPLACE TABLE ecommerce.bronze_products USING iceberg AS 
SELECT * FROM `bigquery-public-data.thelook_ecommerce.products`;

