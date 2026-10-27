-- ============================================================================
-- DEMO 21: LARGE-SCALE DOCUMENT PROCESSING VIA AI FUNCTIONS
-- ============================================================================

USE lakehouse_samples;
CREATE NAMESPACE IF NOT EXISTS procurement;

-- Step 1: Ingest raw PDF documents from GCS bucket
CREATE OR REPLACE TEMPORARY VIEW raw_vendor_docs
USING binaryFile
OPTIONS (
  path "gs://orionis-lakehouse-landing/vendor_invoices/*.pdf"
);

-- Step 2: Parse raw unstructured PDF binaries into structured text and tables
CREATE OR REPLACE TEMPORARY VIEW parsed_documents AS
SELECT
  path AS file_path,
  modificationTime AS ingested_at,
  ai_parse_document(content) AS doc_payload
FROM raw_vendor_docs;

-- Step 3: Extract business fields and mask sensitive PII/financial data into an Iceberg table
CREATE OR REPLACE TABLE procurement.curated_vendor_invoices
USING iceberg
AS
SELECT
  file_path,
  ingested_at,
  -- Extract key document identifiers and metadata
  ai_extract(
    doc_payload.text, 
    ARRAY('vendor_name', 'po_number', 'part_number', 'certification_class', 'total_amount')
  ) AS extracted_metadata,
  
  -- Extract specific line-item tables embedded in the document
  doc_payload.tables AS line_item_tables,

  -- Redact sensitive vendor banking information, tax IDs, and personal phone numbers
  ai_mask(
    doc_payload.text, 
    ARRAY('tax_id', 'bank_account', 'phone_number', 'email')
  ) AS sanitized_text_audit
FROM parsed_documents;

-- Step 4: Validate extraction and masking in the production Iceberg table
SELECT
  file_path,
  extracted_metadata.vendor_name AS vendor,
  extracted_metadata.po_number AS po_number,
  extracted_metadata.certification_class AS cert_class,
  extracted_metadata.total_amount AS total_amount,
  SUBSTRING(sanitized_text_audit, 1, 120) AS sanitized_snippet
FROM procurement.curated_vendor_invoices
LIMIT 10;
