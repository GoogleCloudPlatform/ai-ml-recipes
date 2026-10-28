# Demo 52: Automating pipeline deployments with Git CI/CD

Declarative orchestration and Git CI/CD for the Demo 51 dbt medallion
pipeline on Managed Service for Apache Spark, using Google Cloud
Orchestration Pipelines.

| File | Purpose |
| --- | --- |
| `dev-pipeline.yaml` | Declarative pipeline: nightly schedule, Bronze ingestion on Serverless Spark, dbt build, Gold verification |
| `deployment.yaml` | Multi-environment manifest (dev, staging, prod) with variable substitutions |
| `.github/workflows/validate.yaml` | CI: validates dbt models and the pipeline for every environment on pull requests |
| `.github/workflows/deploy.yaml` | CD: promotes the bundle dev -> staging -> prod on push |

The pipeline references `setup_bronze_layer.sql` and `verify_metrics.sql` from
the dbt project of [Demo 51](../51-dbt-pipelines/).

## Runtime commands

```sh
# 1. Validate pipeline schema & variable bindings across dev, staging, and prod:
gcloud beta orchestration-pipelines validate --environment=dev
gcloud beta orchestration-pipelines validate --environment=staging
gcloud beta orchestration-pipelines validate --environment=prod

# 2. Commit and push to trigger automated GitHub Actions CI/CD promotion:
git add dev-pipeline.yaml deployment.yaml .github/workflows/
git commit -m "Add declarative orchestration pipeline and multi-stage Git CI/CD"
git push origin main
```
