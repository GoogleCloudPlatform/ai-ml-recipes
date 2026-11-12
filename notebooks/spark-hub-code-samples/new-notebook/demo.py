# New notebook on Managed Service for Apache Spark.
# Run in the Cloud Shell Editor as a notebook cell.

# %pip install 'google-cloud-spark-connect[client]==2.1.0'
from google.cloud.managed_spark_connect import ManagedSparkSession

spark = (
    ManagedSparkSession.builder
    .projectId("YOUR_PROJECT_ID")
    .location("YOUR_REGION")
    .sessionTemplate("YOUR_RUNTIME_PROFILE")  # replace this with your Runtime Profile name
    .getOrCreate()
)
