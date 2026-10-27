# New notebook on Managed Service for Apache Spark.
# Run in the Cloud Shell Editor as a notebook cell.

# %pip install 'google-cloud-spark-connect[client]==2.1.0'
from google.cloud.managed_spark_connect import ManagedSparkSession

spark = (
    ManagedSparkSession.builder
    .projectId("devx-customer-demos")
    .location("us-east4")
    .sessionTemplate("dsml")  # replace this with your Runtime Profile name
    .getOrCreate()
)
