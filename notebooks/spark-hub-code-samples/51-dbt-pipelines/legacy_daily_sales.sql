-- ============================================================================
-- LEGACY MONOLITHIC PIPELINE (DO NOT EDIT - FRAGILE NIGHTLY JOB)
-- File: legacy_daily_sales.sql
-- Warning: Single 300+ line script with hardcoded joins, inline CTEs,
--          zero data quality tests, and no environment isolation.
-- ============================================================================

INSERT OVERWRITE TABLE ecommerce.exec_daily_cube_kpis
WITH raw_orders_unfiltered AS (
    -- BUG #1: No filter for internal sandbox accounts (`status = 'Test_Account'`)
    --         or cancelled test orders! Corrupts downstream executive KPIs.
    SELECT
        CAST(o.order_id AS STRING)                  AS raw_order_id,
        CAST(o.user_id AS STRING)                   AS raw_user_id,
        o.status                                    AS raw_status_untrimmed,
        o.gender                                    AS raw_gender,
        o.created_at                                AS raw_created_str,
        o.shipped_at                                AS raw_shipped_str,
        CAST(o.num_of_item AS INT)                  AS raw_item_cnt,
        SUBSTR(o.created_at, 1, 10)                 AS order_dt_str,
        SUBSTR(o.created_at, 12, 8)                 AS order_tm_str,
        CASE
            WHEN o.created_at LIKE '%/%' THEN TO_TIMESTAMP(o.created_at, 'MM/dd/yyyy HH:mm:ss')
            WHEN o.created_at LIKE '%-%' THEN CAST(o.created_at AS TIMESTAMP)
            ELSE NULL
        END                                         AS parsed_order_ts,
        CASE
            WHEN o.shipped_at LIKE '%/%' THEN TO_TIMESTAMP(o.shipped_at, 'MM/dd/yyyy HH:mm:ss')
            WHEN o.shipped_at LIKE '%-%' THEN CAST(o.shipped_at AS TIMESTAMP)
            ELSE NULL
        END                                         AS parsed_ship_ts
    FROM `bigquery-public-data.thelook_ecommerce.orders` o
    WHERE o.created_at IS NOT NULL
),

raw_products_uncleaned AS (
    -- BUG #2: Trailing whitespace in `name` and `category` causes CASE WHEN
    --         subsystem mappings to fall through to 'UNKNOWN_SUBSYSTEM'!
    SELECT
        p.id                                        AS raw_prod_id,
        p.name                                      AS untrimmed_prod_name,
        p.category                                  AS untrimmed_category,
        p.brand                                     AS untrimmed_brand,
        p.retail_price                              AS unrounded_retail_price,
        p.cost                                      AS unrounded_unit_cost,
        (p.retail_price - p.cost)                   AS raw_unit_spread,
        CASE
            WHEN p.category = 'Active'      THEN 'EPS (Electrical Power Systems)'
            WHEN p.category = 'Outerwear'   THEN 'EPS (Electrical Power Systems)'
            WHEN p.category = 'Sweaters'    THEN 'EPS (Electrical Power Systems)'
            WHEN p.category = 'Jeans'       THEN 'ADCS (Attitude Determination & Control)'
            WHEN p.category = 'Pants'       THEN 'ADCS (Attitude Determination & Control)'
            WHEN p.category = 'Shorts'      THEN 'ADCS (Attitude Determination & Control)'
            WHEN p.category = 'Accessories' THEN 'OBDH (On-Board Data Handling)'
            WHEN p.category = 'Swim'        THEN 'OBDH (On-Board Data Handling)'
            WHEN p.category = 'Underwear'   THEN 'Structure & Thermal'
            WHEN p.category = 'Sleepwear'   THEN 'Structure & Thermal'
            ELSE 'Payload & Scientific Instrumentation'
        END                                         AS fragile_subsystem_label
    FROM `bigquery-public-data.thelook_ecommerce.products` p
),

raw_line_items_joined AS (
    -- BUG #3: Full table scan every night (no incremental watermark / MERGE).
    --         Reprocesses all historical rows and duplicates un-deduped retries.
    SELECT
        oi.id                                       AS order_item_id,
        oi.order_id                                 AS order_id,
        oi.user_id                                  AS customer_id,
        oi.product_id                               AS product_id,
        oi.sale_price                               AS raw_sale_price,
        ro.raw_status_untrimmed                     AS order_status,
        ro.raw_gender                               AS customer_gender,
        ro.parsed_order_ts                          AS order_timestamp,
        ro.parsed_ship_ts                           AS shipping_timestamp,
        ro.raw_item_cnt                             AS items_count,
        rp.untrimmed_prod_name                      AS product_name,
        rp.untrimmed_category                       AS raw_category,
        rp.untrimmed_brand                          AS brand,
        rp.fragile_subsystem_label                  AS cubesat_subsystem,
        rp.unrounded_retail_price                   AS list_price,
        rp.unrounded_unit_cost                      AS unit_cost,
        (oi.sale_price - rp.unrounded_unit_cost)    AS unverified_profit_margin,
        CASE
            WHEN oi.sale_price <= 0 THEN -9999.99
            ELSE (oi.sale_price - rp.unrounded_unit_cost) / oi.sale_price
        END                                         AS margin_pct_unbounded
    FROM `bigquery-public-data.thelook_ecommerce.order_items` oi
    LEFT JOIN raw_orders_unfiltered ro
        ON CAST(oi.order_id AS STRING) = ro.raw_order_id
    LEFT JOIN raw_products_uncleaned rp
        ON oi.product_id = rp.raw_prod_id
),

legacy_regional_rollups AS (
    -- Hardcoded regional tax & telemetry adjustments copy-pasted across 4 CTEs
    SELECT
        lij.*,
        CASE
            WHEN lij.cubesat_subsystem LIKE 'EPS%'  THEN lij.raw_sale_price * 1.00
            WHEN lij.cubesat_subsystem LIKE 'ADCS%' THEN lij.raw_sale_price * 1.00
            WHEN lij.cubesat_subsystem LIKE 'OBDH%' THEN lij.raw_sale_price * 1.00
            ELSE lij.raw_sale_price
        END                                         AS adj_gross_revenue,
        CASE
            WHEN lij.order_status = 'Test_Account' THEN 'LEAKED_SANDBOX_ROW'
            WHEN lij.unverified_profit_margin < 0  THEN 'NEGATIVE_MARGIN_UNCAUGHT'
            ELSE 'UNAUDITED_PROD_ROW'
        END                                         AS silent_corruption_flag,
        DATEDIFF(lij.shipping_timestamp, lij.order_timestamp) AS fulfillment_lag_days
    FROM raw_line_items_joined lij
),

legacy_inventory_backfill AS (
    SELECT
        lrr.cubesat_subsystem,
        lrr.product_id,
        lrr.product_name,
        COUNT(*)                                    AS raw_line_cnt,
        COUNT(DISTINCT lrr.order_id)                AS raw_order_cnt,
        SUM(lrr.adj_gross_revenue)                  AS total_gross_rev,
        SUM(lrr.unit_cost)                          AS total_unit_cost,
        SUM(lrr.unverified_profit_margin)           AS total_net_margin,
        AVG(lrr.unverified_profit_margin)           AS avg_net_margin,
        MIN(lrr.unverified_profit_margin)           AS min_margin_observed,
        MAX(lrr.unverified_profit_margin)           AS max_margin_observed,
        SUM(CASE WHEN lrr.order_status = 'Test_Account' THEN 1 ELSE 0 END) AS leaked_test_orders
    FROM legacy_regional_rollups lrr
    GROUP BY
        lrr.cubesat_subsystem,
        lrr.product_id,
        lrr.product_name
)

-- BUG #4: Zero assertions on NULL primary keys or negative profit margins!
--         If `Test_Account` orders have $0.00 sale_price, executive dashboards
--         display negative margins silently hours later.
SELECT
    lib.cubesat_subsystem,
    SUM(lib.raw_order_cnt)                          AS total_orders,
    ROUND(SUM(lib.total_gross_rev), 2)              AS gross_revenue_usd,
    ROUND(SUM(lib.total_unit_cost), 2)              AS total_cost_usd,
    ROUND(SUM(lib.total_net_margin), 2)             AS net_profit_usd,
    ROUND(AVG(lib.avg_net_margin), 2)               AS avg_item_margin_usd,
    MIN(lib.min_margin_observed)                    AS worst_item_margin_usd,
    SUM(lib.leaked_test_orders)                     AS silent_sandbox_leaks,
    CURRENT_TIMESTAMP()                             AS batch_loaded_at
FROM legacy_inventory_backfill lib
GROUP BY lib.cubesat_subsystem
ORDER BY gross_revenue_usd DESC;
