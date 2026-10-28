# Spark Hub code samples

Sample code behind the demos on the Managed Service for Apache Spark overview
page in the Google Cloud console. Each demo lives in its own folder and is
opened in the Cloud Shell Editor from the "View code" action of its card.

| Folder | Demo |
| --- | --- |
| `new-sql-query/` | Starter Spark SQL file for "New SQL query" |
| `new-notebook/` | Starter notebook for "New notebook" (`demo.ipynb`; `demo.py` holds the same cell) |
| `01-iceberg-branching/` | Git-style branching: write-audit-publish via Iceberg branching |
| `03-iceberg-rollback/` | Instant disaster recovery and zero-scan rollback via Iceberg snapshots |
| `21-document-processing-ai/` | Large-scale document processing with Spark SQL AI functions |
| `22-customer-feedback-nlp/` | Customer feedback sentiment and triage with Spark SQL AI functions |
| `23-predictive-operations/` | Time-series forecasting and anomaly attribution with Spark SQL AI functions |
| `51-dbt-pipelines/` | Production-grade dbt pipelines: Bronze/Silver/Gold medallion models on Managed Spark |
| `52-deployment-automation/` | Automating pipeline deployments with Orchestration Pipelines and Git CI/CD |
| `103-serverless-interactive/` | Interactive analysis on the lakehouse with Managed Spark |

The `.sql` files are Spark SQL scripts for the Cloud Shell Editor SQL editor;
the `@datacloud.settings` header selects Managed Service for Apache Spark and
the Runtime Profile (`sessionTemplate`) to run against.
