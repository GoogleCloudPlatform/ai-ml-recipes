# Orionis Industries — Medallion dbt Pipeline on Managed Serverless Spark

This standalone project transforms a fragile, monolithic daily SQL script (`legacy_daily_sales.sql`) into a modular, tested **Three-Tier Medallion (`Bronze` → `Silver` → `Gold`)** `dbt` pipeline running serverlessly on **Google Cloud Managed Service for Apache Spark** and **Apache Iceberg** via **Spark Connect**.

---

## Project Structure

```text
.
├── legacy_daily_sales.sql                  # Legacy monolithic SQL script (before dbt modularization)
├── dbt_project.yml                         # dbt project configuration (Silver = views, Gold = Iceberg tables)
├── profiles.yml                            # Spark Connect profile (method: session)
├── dbt_wrapper.py                          # Standalone Spark Connect session hook & CLI runner
├── sitecustomize.py                        # Auto-loads dbt_wrapper when PYTHONPATH=. is set
├── requirements.txt                        # Python dependencies (dbt-core, dbt-spark, dataproc-spark-connect)
├── setup_bronze_layer.sql                  # Step 1: SQL reference for raw Bronze Iceberg tables
├── models/
│   ├── sources.yml                         # Bronze source table declarations
│   ├── schema.yml                          # Automated data quality tests (unique, not_null)
│   ├── silver/
│   │   ├── sil_products.sql                # Cleaned & standardized products view
│   │   └── sil_orders.sql                  # Cleaned orders view (filters out Test_Account)
│   └── gold/
│       ├── gold_dim_products.sql           # Product dimension mapped to DIY CubeSat subsystems
│       └── gold_fct_orders.sql             # Incremental Iceberg fact table (revenue & profit margins)
├── tests/
│   └── assert_positive_profit_margin.sql   # Singular test asserting net_profit_margin >= 0.00
└── verify_metrics.sql                      # Step 5: Business intelligence verification query
```

---

## Quickstart for Developers

### 1. Install Dependencies
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### 2. Configure Your GCP Environment Variables
Set your Google Cloud project, region, GCS bucket (for Iceberg warehouse storage), and Dataproc service account:
```bash
export GCP_PROJECT="your-gcp-project-id"
export GCP_REGION="us-central1"
export BUCKET_NAME="your-gcs-warehouse-bucket"
export SPARK_SERVICE_ACCOUNT="your-service-account@your-project.iam.gserviceaccount.com"
export S8S_SESSION_ID="orionis-dbt-s8s"
```
*(If omitted, `dbt_wrapper.py` defaults to `google.com:hadoop-cloud-dev`, `us-central1`, `sglodha-iceberg-wap`, and `orionis-dbt-s8s`).*

### 3. Run the End-to-End Demo
```bash
# Step 1: Ingest the 3 Bronze Iceberg tables from BigQuery public data
python dbt_wrapper.py setup-bronze

# Step 2: Build Silver views, Gold Iceberg tables, and run 21 data quality tests
PYTHONPATH=. dbt build --profiles-dir .
# (or: python dbt_wrapper.py build)

# Step 3: Query final Gold Business Intelligence metrics by CubeSat subsystem
python dbt_wrapper.py verify
```
