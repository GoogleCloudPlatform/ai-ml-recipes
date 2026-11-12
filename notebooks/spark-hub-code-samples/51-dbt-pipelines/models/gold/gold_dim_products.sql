{{ config(
    materialized='table',
    file_format='iceberg'
) }}

-- Maps e-commerce categories directly to Orionis DIY CubeSat Subsystems
SELECT
    product_id,
    product_name,
    brand,
    retail_price,
    unit_cost,
    CASE 
        WHEN raw_category IN ('Active', 'Outerwear & Coats', 'Sweaters') THEN 'EPS (Electrical Power Systems)'
        WHEN raw_category IN ('Jeans', 'Pants', 'Shorts') THEN 'ADCS (Attitude Determination & Control)'
        WHEN raw_category IN ('Accessories', 'Swim') THEN 'OBDH (On-Board Data Handling)'
        WHEN raw_category IN ('Underwear', 'Sleep & Lounge') THEN 'Structure & Thermal'
        ELSE 'Payload & Scientific Instrumentation'
    END AS cubesat_subsystem
FROM {{ ref('sil_products') }}

