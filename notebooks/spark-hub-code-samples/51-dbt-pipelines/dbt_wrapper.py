"""Standalone runner & Spark Connect adapter hook for the Orionis Medallion dbt Pipeline.

Allows any developer to run the full demo end-to-end against Google Cloud Managed Serverless Spark:
  1. Ingest Bronze Iceberg tables:
       python dbt_wrapper.py setup-bronze
  2. Run dbt build (Silver views, Gold Iceberg tables, and 21 data quality tests):
       python dbt_wrapper.py build
       # OR using the standard dbt CLI:
       PYTHONPATH=. dbt build --profiles-dir .
  3. Run final Business Intelligence verification query:
       python dbt_wrapper.py verify
"""

import contextlib
import io
import logging
import os
import re
import sys
import warnings

warnings.filterwarnings("ignore", category=UserWarning)
logging.getLogger("google.cloud.managed_spark_connect").setLevel(logging.ERROR)

_ACTIVE_SPARK_SESSION = None


def _wrap_spark_sql_for_iceberg_views(spark) -> None:
    """Allows `CREATE OR REPLACE VIEW` in dbt-spark to succeed on Iceberg HadoopCatalog."""
    orig_sql = spark.sql

    def _patched_sql(sqlQuery: str, *args, **kwargs):
        try:
            return orig_sql(sqlQuery, *args, **kwargs)
        except Exception as exc:
            msg = str(exc)
            if "view" in msg.lower() and re.search(r"\bview\b", sqlQuery, flags=re.IGNORECASE):
                rewritten = re.sub(
                    r"create\s+or\s+replace\s+view\s+([^\s(]+)\s+as",
                    r"CREATE OR REPLACE TABLE \1 USING iceberg AS",
                    sqlQuery,
                    flags=re.IGNORECASE,
                )
                rewritten = re.sub(
                    r"drop\s+view\s+if\s+exists",
                    "DROP TABLE IF EXISTS",
                    rewritten,
                    flags=re.IGNORECASE,
                )
                if rewritten != sqlQuery:
                    return orig_sql(rewritten, *args, **kwargs)
            raise

    spark.sql = _patched_sql


def get_or_create_serverless_spark():
    global _ACTIVE_SPARK_SESSION
    if _ACTIVE_SPARK_SESSION is not None:
        return _ACTIVE_SPARK_SESSION

    from google.cloud.dataproc_v1 import Session
    try:
        from google.cloud.dataproc_spark_connect import DataprocSparkSession as ServerlessSparkSession
    except ImportError:
        from google.cloud.managed_spark_connect import ManagedSparkSession as ServerlessSparkSession

    project_id = os.environ.get("GCP_PROJECT", "google.com:hadoop-cloud-dev")
    region = os.environ.get("GCP_REGION", "us-central1")
    bucket_name = os.environ.get("BUCKET_NAME", "sglodha-iceberg-wap")
    subnetwork_uri = os.environ.get("SUBNETWORK_URI", "default-auto")
    service_account = os.environ.get(
        "SPARK_SERVICE_ACCOUNT",
        "dataproc-service-account@hadoop-cloud-dev.google.com.iam.gserviceaccount.com",
    )
    session_id = os.environ.get("S8S_SESSION_ID", "orionis-dbt-s8s")

    session_config = Session()
    session_config.environment_config.execution_config.subnetwork_uri = subnetwork_uri
    session_config.environment_config.execution_config.service_account = service_account
    session_config.environment_config.execution_config.idle_ttl = {"seconds": 3600}
    session_config.runtime_config.properties.update(
        {
            "spark.sql.extensions": "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions",
            "spark.sql.catalog.lakehouse_samples": "org.apache.iceberg.spark.SparkCatalog",
            "spark.sql.catalog.lakehouse_samples.type": "hadoop",
            "spark.sql.catalog.lakehouse_samples.warehouse": f"gs://{bucket_name}/orionis_warehouse",
            "spark.sql.defaultCatalog": "lakehouse_samples",
        }
    )

    with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
        try:
            from google.cloud import dataproc_v1
            sc = dataproc_v1.SessionControllerClient(
                client_options={"api_endpoint": f"{region}-dataproc.googleapis.com:443"}
            )
            sess_name = f"projects/{project_id}/locations/{region}/sessions/{session_id}"
            existing = sc.get_session(name=sess_name)
            if existing.state in (
                dataproc_v1.Session.State.TERMINATED,
                dataproc_v1.Session.State.FAILED,
            ):
                sc.delete_session(name=sess_name).result(timeout=60)
        except Exception:
            pass
        spark = (
            ServerlessSparkSession.builder.projectId(project_id)
            .location(region)
            .dataprocSessionId(session_id)
            .dataprocSessionConfig(session_config)
            .getOrCreate()
        )

    _wrap_spark_sql_for_iceberg_views(spark)
    _ACTIVE_SPARK_SESSION = spark
    return _ACTIVE_SPARK_SESSION


def install_dbt_spark_connect_hook() -> None:
    try:
        from pyspark.sql import SparkSession as ClassicSparkSession
        ClassicSparkSession.Builder.getOrCreate = lambda _self: get_or_create_serverless_spark()
    except Exception:
        pass


install_dbt_spark_connect_hook()


def setup_bronze_tables() -> None:
    """Ingests the 3 Bronze Iceberg tables from bigquery-public-data.thelook_ecommerce."""
    spark = get_or_create_serverless_spark()
    print("Creating namespace `lakehouse_samples.ecommerce`...")
    spark.sql("CREATE NAMESPACE IF NOT EXISTS lakehouse_samples.ecommerce")
    for tbl in ("orders", "order_items", "products"):
        print(f"Ingesting `ecommerce.bronze_{tbl}` from `bigquery-public-data.thelook_ecommerce.{tbl}`...")
        df = spark.read.format("bigquery").option(
            "table", f"bigquery-public-data.thelook_ecommerce.{tbl}"
        ).load()
        df.writeTo(f"lakehouse_samples.ecommerce.bronze_{tbl}").using("iceberg").createOrReplace()
    print("Bronze layer tables ready!")


def verify_gold_metrics() -> None:
    """Runs verify_metrics.sql on Managed Serverless Spark and prints the output table."""
    spark = get_or_create_serverless_spark()
    query = """
        SELECT
            cubesat_subsystem,
            COUNT(DISTINCT order_id) AS total_orders,
            ROUND(SUM(gross_revenue), 2) AS total_revenue_usd,
            ROUND(AVG(net_profit_margin), 2) AS avg_item_margin_usd
        FROM lakehouse_samples.ecommerce.gold_fct_orders
        GROUP BY cubesat_subsystem
        ORDER BY total_revenue_usd DESC
    """
    spark.sql(query).show(truncate=False)


if __name__ == "__main__":
    args = sys.argv[1:]
    if args and args[0] == "setup-bronze":
        setup_bronze_tables()
        sys.exit(0)
    if args and args[0] == "verify":
        verify_gold_metrics()
        sys.exit(0)

    from dbt.cli.main import dbtRunner

    cli_args = args or ["build"]
    if "--profiles-dir" not in cli_args:
        cli_args.extend(["--profiles-dir", "."])
    res = dbtRunner().invoke(cli_args)
    sys.exit(0 if res.success else 1)
