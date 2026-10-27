-- ============================================================================
-- DEMO 22: REAL-TIME NLP & SENTIMENT TRIAGE PIPELINE (KAFKA SOURCE)
-- ============================================================================

USE lakehouse_samples;
CREATE NAMESPACE IF NOT EXISTS mission_support;

-- Step 1: Read raw messages from the mission support Kafka topic
CREATE OR REPLACE TEMPORARY VIEW raw_kafka_stream
USING kafka
OPTIONS (
  "kafka.bootstrap.servers" "10.0.0.20:9092,10.0.0.21:9092",
  "subscribe" "orion-mission-support-tickets",
  "startingOffsets" "earliest",
  "failOnDataLoss" "false"
);

-- Step 2: Deserialize JSON Kafka payloads into structured columns
CREATE OR REPLACE TEMPORARY VIEW parsed_support_tickets AS
SELECT
  CAST(key AS STRING) AS ticket_key,
  timestamp AS kafka_timestamp,
  from_json(
    CAST(value AS STRING),
    'ticket_id STRING, customer_id STRING, created_at TIMESTAMP, original_language STRING, raw_message STRING'
  ) AS payload
FROM raw_kafka_stream;

-- Step 3: Transform, clean, enrich with AI functions, and store into an Iceberg table
CREATE OR REPLACE TABLE mission_support.triaged_tickets
USING iceberg
AS
WITH normalized_tickets AS (
  SELECT
    payload.ticket_id AS ticket_id,
    payload.customer_id AS customer_id,
    payload.created_at AS created_at,
    payload.original_language AS original_language,
    payload.raw_message AS raw_message,
    -- Step 3a: Normalize incoming multi-lingual tickets to English
    ai_translate(payload.raw_message, 'en') AS english_text
  FROM parsed_support_tickets
),
cleaned_tickets AS (
  SELECT
    ticket_id,
    customer_id,
    created_at,
    english_text,
    -- Step 3b: Clean up terminal logs and colloquial phrasing
    ai_fix_grammar(english_text) AS cleaned_text
  FROM normalized_tickets
)
SELECT
  ticket_id,
  customer_id,
  created_at,
  cleaned_text,
  -- Step 3c: Gauge customer urgency and emotional sentiment
  ai_analyze_sentiment(cleaned_text) AS customer_sentiment,
  
  -- Step 3d: Classify ticket into target engineering triage team
  ai_classify(
    cleaned_text, 
    ARRAY('Flight Software', 'Hardware Power System', 'Orbital Mechanics', 'Ground Station Comms', 'Billing')
  ) AS issue_category,
  
  -- Step 3e: Generate concise summary for flight engineers
  ai_summarize(cleaned_text, 20) AS engineer_brief
FROM cleaned_tickets;

-- Step 4: Query critical escalations from the Iceberg table for immediate dispatch
SELECT 
  ticket_id,
  issue_category,
  customer_sentiment,
  engineer_brief
FROM mission_support.triaged_tickets
WHERE customer_sentiment = 'negative' 
  AND issue_category IN ('Flight Software', 'Hardware Power System')
ORDER BY created_at DESC;
