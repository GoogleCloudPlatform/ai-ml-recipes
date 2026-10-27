-- ============================================================================
-- DEMO 23: TIME-SERIES FORECASTING & ANOMALY ATTRIBUTION
-- ============================================================================

USE lakehouse_samples;
CREATE NAMESPACE IF NOT EXISTS telemetry_ops;

-- Step 1: Persist aggregated hourly ground station downlink metrics into an Iceberg table
CREATE OR REPLACE TABLE telemetry_ops.hourly_station_traffic
USING iceberg
AS
SELECT
  station_id,
  DATE_TRUNC('hour', recorded_at) AS metric_timestamp,
  AVG(downlink_gbps) AS avg_bandwidth_gbps,
  AVG(solar_flux_index) AS avg_solar_flux,
  COUNT(DISTINCT satellite_id) AS active_sats
FROM lakehouse_samples.telemetry_ops.antenna_logs
WHERE recorded_at >= CURRENT_DATE() - INTERVAL 30 DAYS
GROUP BY 1, 2;

-- Step 2: Generate 72-hour forecast using ai_forecast table-valued function into an Iceberg table
CREATE OR REPLACE TABLE telemetry_ops.bandwidth_forecast_72h
USING iceberg
AS
SELECT * FROM ai_forecast(
  TABLE(telemetry_ops.hourly_station_traffic),
  time_col => 'metric_timestamp',
  target_col => 'avg_bandwidth_gbps',
  group_col => 'station_id',
  horizon => 72,             -- Forecast next 72 hours
  frequency => '1 hour',
  prediction_interval => 0.95 -- 95% confidence bounds
);

-- Step 3: Identify underlying drivers causing peak bandwidth consumption into an Iceberg table
CREATE OR REPLACE TABLE telemetry_ops.saturation_drivers
USING iceberg
AS
SELECT * FROM ai_top_drivers(
  TABLE(telemetry_ops.hourly_station_traffic),
  target_col => 'avg_bandwidth_gbps',
  feature_cols => ARRAY('avg_solar_flux', 'active_sats')
);

-- Step 4: Query potential saturation breaches over the next 24 hours
SELECT
  station_id,
  forecast_timestamp,
  forecast_value AS projected_gbps,
  upper_bound AS max_expected_gbps,
  CASE 
    WHEN upper_bound > 45.0 THEN 'CRITICAL: RISK OF DATA LOSS'
    WHEN upper_bound > 35.0 THEN 'WARNING: HIGH LOAD'
    ELSE 'NOMINAL'
  END AS capacity_status
FROM telemetry_ops.bandwidth_forecast_72h
WHERE forecast_timestamp BETWEEN CURRENT_TIMESTAMP() AND CURRENT_TIMESTAMP() + INTERVAL 24 HOURS
  AND upper_bound > 35.0
ORDER BY upper_bound DESC;
