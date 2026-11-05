-- ============================================================================
-- 5. BUSINESS INTELLIGENCE VERIFICATION
-- ============================================================================
USE lakehouse_samples;

-- Verify results & fetch business metrics:
SELECT
    cubesat_subsystem,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(gross_revenue), 2) AS total_revenue_usd,
    ROUND(AVG(net_profit_margin), 2) AS avg_item_margin_usd
FROM ecommerce.gold_fct_orders
GROUP BY cubesat_subsystem
ORDER BY total_revenue_usd DESC;

