/* @datacloud.settings
{
  "version": 1,
  "service": "SPARK",
  "connectionInfo": {
    "sessionTemplate": "interactive-runtime"
  },
  "dialect": "ANSI_SQL"
}
*/

-- Demo 103: Interactive analysis on the lakehouse with Managed Spark (Spark SQL)
-- Run in the Cloud Shell Editor SQL editor.
-- Query settings: Managed Apache Spark, runtime profile "interactive-lakehouse".
-- The runtime profile makes the Lakehouse runtime catalog the default catalog.

-- 1. Public Iceberg datasets are attached to every session.
SHOW TABLES IN `lakehouse-public-data`.new_york_taxi_trips;

-- 2. 40M NYC yellow taxi trips from 2022, in Apache Iceberg.
SELECT COUNT(*) AS trips
FROM `lakehouse-public-data`.new_york_taxi_trips.tlc_yellow_trips_2022;

-- 3. When does demand peak? Average pickups per hour, weekdays vs. weekends.
SELECT
  IF(dayofweek(pickup_datetime) IN (1, 7), 'Weekend', 'Weekday') AS day_type,
  hour(pickup_datetime) AS hour,
  ROUND(COUNT(*) / COUNT(DISTINCT to_date(pickup_datetime))) AS trips_per_day
FROM `lakehouse-public-data`.new_york_taxi_trips.tlc_yellow_trips_2022
WHERE year(pickup_datetime) = 2022
GROUP BY day_type, hour
ORDER BY day_type, hour;

-- 4. Save the 10 busiest pickup zones to your lakehouse as an Iceberg table.
USE `standard-lh-catalog-us-central1`;  -- Your project's Lakehouse runtime catalog
CREATE NAMESPACE IF NOT EXISTS nyc_taxi_insights;

CREATE OR REPLACE TABLE nyc_taxi_insights.top_pickup_zones USING iceberg AS
SELECT
  z.zone_name,
  z.borough,
  COUNT(*) AS trips,
  ROUND(AVG(CAST(t.total_amount AS DOUBLE)), 2) AS avg_fare_usd
FROM `lakehouse-public-data`.new_york_taxi_trips.tlc_yellow_trips_2022 AS t
JOIN `lakehouse-public-data`.new_york_taxi_trips.taxi_zone_geom AS z
  ON t.pickup_location_id = z.zone_id
WHERE t.trip_distance > 0 AND t.total_amount > 0
GROUP BY z.zone_name, z.borough
ORDER BY trips DESC
LIMIT 10;

SELECT * FROM nyc_taxi_insights.top_pickup_zones;
