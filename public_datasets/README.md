# Available datasets

The following GCS bucket contains the files for each available dataset

|                GCP_PROJECT  |                                                                                                                    GCS bucket|
|-----------------------------|------------------------------------------------------------------------------------------------------------------------------|
|dataproc-workspaces-notebooks|[gs://dataproc-metastore-public-binaries](https://console.cloud.google.com/storage/browser/dataproc-metastore-public-binaries)|

#### Examples reading the datasets using PySpark

```
dataset_df = spark.read.option("header", True).csv("gs://dataproc-metastore-public-binaries/ai4i_2020_predictive_maintenance/")
dataset_df = spark.read.parquet("gs://dataproc-metastore-public-binaries/real_estate_sales/")
dataset_df = spark.read.format("binaryFile").option("recursiveFileLookup", "true").load("gs://dataproc-metastore-public-binaries/youtube_ucg/")
```

[**cuad_v1**](https://www.atticusprojectai.org/cuad)   
GCS bucket path: gs://dataproc-metastore-public-binaries/cuad_v1/full_contract_pdf/
- Format: .pdf
- Metastore referece: public_datasets.cuad_v1
- Description: 510 PDF files of legal contracts

|                path|    modificationTime| length|             content|
|--------------------|--------------------|-------|--------------------|
|gs://dataproc-met...|2023-05-15 20:53:...|3683550|[25 50 44 46 2D 3...|
|gs://dataproc-met...|2023-05-15 20:53:...|2881262|[25 50 44 46 2D 3...|
|gs://dataproc-met...|2023-05-15 20:54:...|1778356|[25 50 44 46 2D 3...|
|gs://dataproc-met...|2023-05-15 20:53:...|1557129|[25 50 44 46 2D 3...|
|gs://dataproc-met...|2023-05-15 20:53:...|1452180|[25 50 44 46 2D 3...|

[**winequality_red**](https://archive.ics.uci.edu/dataset/186/wine+quality)   
GCS bucket path: gs://dataproc-metastore-public-binaries/winequality_red/
- Format: .csv
- Metastore referece: public_datasets.winequality_red
- Description: 4898 Wine quality data of white vinho verde samples

|fixed_acidity|volatile_acidity|citric_acid|residual_sugar|chlorides|free_sulfur_dioxide|total_sulfur_dioxide|density|  pH|sulphates|alcohol|quality|
|-------------|----------------|-----------|--------------|---------|-------------------|--------------------|-------|----|---------|-------|-------|
|          7.0|            0.27|       0.36|          20.7|    0.045|               45.0|               170.0|  1.001| 3.0|     0.45|    8.8|      6|
|          6.3|             0.3|       0.34|           1.6|    0.049|               14.0|               132.0|  0.994| 3.3|     0.49|    9.5|      6|
|          8.1|            0.28|        0.4|           6.9|     0.05|               30.0|                97.0| 0.9951|3.26|     0.44|   10.1|      6|
|          7.2|            0.23|       0.32|           8.5|    0.058|               47.0|               186.0| 0.9956|3.19|      0.4|    9.9|      6|
|          7.2|            0.23|       0.32|           8.5|    0.058|               47.0|               186.0| 0.9956|3.19|      0.4|    9.9|      6|

[**winequality_white**](https://archive.ics.uci.edu/dataset/186/wine+quality)   
GCS bucket path: gs://dataproc-metastore-public-binaries/winequality_white/
- Format: .csv
- Metastore referece: public_datasets.winequality_white
- Description: 1599 Wine quality data of red vinho verde samples

|fixed_acidity|volatile_acidity|citric_acid|residual_sugar|chlorides|free_sulfur_dioxide|total_sulfur_dioxide|density|  pH|sulphates|alcohol|quality|
|-------------|----------------|-----------|--------------|---------|-------------------|--------------------|-------|----|---------|-------|-------|
|          7.0|            0.27|       0.36|          20.7|    0.045|               45.0|               170.0|  1.001| 3.0|     0.45|    8.8|      6|
|          6.3|             0.3|       0.34|           1.6|    0.049|               14.0|               132.0|  0.994| 3.3|     0.49|    9.5|      6|
|          8.1|            0.28|        0.4|           6.9|     0.05|               30.0|                97.0| 0.9951|3.26|     0.44|   10.1|      6|
|          7.2|            0.23|       0.32|           8.5|    0.058|               47.0|               186.0| 0.9956|3.19|      0.4|    9.9|      6|
|          7.2|            0.23|       0.32|           8.5|    0.058|               47.0|               186.0| 0.9956|3.19|      0.4|    9.9|      6|

[**real_estate_sales**](https://catalog.data.gov/dataset/real-estate-sales-2001-2018)  
GCS bucket path: gs://dataproc-metastore-public-binaries/real_estate_sales/
- Format: .parquet
- Metastore referece: public_datasets.real_estate_sales
- Description: 997213 samples of real estate sales

| serial_number | list_year | date_recorded | town    | address              | assessed_value | sale_amount | sales_ratio | property_type | residential_type | non_use_code         | assessor_remarks     | opm_remarks          | longitude            | latitude           |
|---------------|-----------|---------------|---------|----------------------|----------------|-------------|-------------|---------------|------------------|----------------------|----------------------|----------------------|----------------------|--------------------|
| 200594        | 2020      | 2021-02-16    | Danbury | 8 HICKORY ST         | 121600.0       | 146216.0    | 0.8316463   | Residential   | Single Family    | 25 - Other           | I11192               | HOUSE HAS SETTLED... |            -73.44696 |           40.41404 |
| 200562        | 2020      | 2021-02-03    | Danbury | 19  MILL RD          | 263600.0       | 415000.0    | 0.6351807   | Residential   | Single Family    | 25 - Other           | AFFORDABLE HOUSIN... | INCORRECT DATA PE... |            -23.42596 |           21.41424 |
| 200968        | 2020      | 2021-05-24    | Danbury | 4A FLIRTATION DR     | 205700.0       | 515000.0    | 0.3994175   | Residential   | Single Family    | 07 - Change in Pr... | B17008               | UPDATED KITCHEN P... |            -73.55596 |           48.43564 |
| 200260        | 2020      | 2020-11-23    | Danbury | 32 COALPIT HILL R... | 84900.0        | 181778.0    | 0.4670532   | Residential   | Condo            | 25 - Other           | J16087-4             | MULTIPLE UNIT SALE   |            -75.46666 |           75.56424 |
| 200262        | 2020      | 2020-11-23    | Danbury | 32 COALPIT HILL R... | 84900.0        | 181778.0    | 0.4670532   | Residential   | Condo            | 25 - Other           | J16087-6             | MULTIPLE UNIT SALE   |            -13.44696 |           22.48524 |

[**sms_spam_collection**](https://archive.ics.uci.edu/dataset/228/sms+spam+collection)  
GCS bucket path: gs://dataproc-metastore-public-binaries/sms_spam_collection/
- Format: .csv
- Metastore referece: public_datasets.sms_spam_collection
- Description: 5574 SMS messages (4827 ham and 747 spam)

|label|                text|
|-----|--------------------|
|  ham|Go until jurong p...|
|  ham|Ok lar... Joking ...|
| spam|Free entry in 2 a...|
|  ham|U dun say so earl...|
|  ham|Nah I don't think...|

[**us_customer_price_index_yearly**](https://data.bls.gov/timeseries/CUUR0000SA0L1E?output_view=pct_12mths)  
GCS bucket path: gs://dataproc-metastore-public-binaries/us_customer_price_index_yearly/
- Format: .csv
- Metastore referece: public_datasets.us_customer_price_index_yearly
- Description: Customer Price Indexes from 1913 to 2022

|Year| CPI|
|----|----|
|1913| 9.9|
|1914|10.0|
|1915|10.1|
|1916|10.9|
|1917|12.8|

[**ai4i_2020_predictive_maintenance**](https://archive.ics.uci.edu/dataset/601/ai4i+2020+predictive+maintenance+dataset)  
GCS bucket path: gs://dataproc-metastore-public-binaries/ai4i_2020_predictive_maintenance/
- Format: .csv
- Metastore referece: public_datasets.ai4i_2020_predictive_maintenance
- Description: 10000 data points stored as rows with 14 features in columns

|udi|product_id|type|air_temperature_k|process_temperature_k|rotational_speed_rpm|torque_nm|tool_wear_min|machine_failure|twf|hdf|pwf|osf|rnf|
|---|----------|----|-----------------|---------------------|--------------------|---------|-------------|---------------|---|---|---|---|---|
|  1|    M14860|   M|            298.1|                308.6|                1551|     42.8|            0|              0|  0|  0|  0|  0|  0|
|  2|    L47181|   L|            298.2|                308.7|                1408|     46.3|            3|              0|  0|  0|  0|  0|  0|
|  3|    L47182|   L|            298.1|                308.5|                1498|     49.4|            5|              0|  0|  0|  0|  0|  0|
|  4|    L47183|   L|            298.2|                308.6|                1433|     39.5|            7|              0|  0|  0|  0|  0|  0|
|  5|    L47184|   L|            298.2|                308.7|                1408|     40.0|            9|              0|  0|  0|  0|  0|  0|

[**stanford_online_products**](https://cvgl.stanford.edu/projects/lifted_struct/)   
GCS bucket path: gs://dataproc-metastore-public-binaries/stanford_online_products/
- Format: .jpg
- Metastore referece: public_datasets.stanford_online_products
- Description: 120k images of 23k classes of online products

|                path|    modificationTime| length|
|--------------------|--------------------|-------|
|gs://dataproc-met...|2023-12-12 20:45:...|3051905|
|gs://dataproc-met...|2023-12-12 20:45:...|2998889|
|gs://dataproc-met...|2023-12-12 20:44:...|2646343|
|gs://dataproc-met...|2023-12-12 20:44:...|2605636|
|gs://dataproc-met...|2023-12-12 20:45:...|2457016|

[**youtube_ucg**](https://media.withyoutube.com/)  
GCS bucket path: gs://dataproc-metastore-public-binaries/youtube_ucg/
- Format: .mp4
- Metastore referece: public_datasets.youtube_ucg
- Description: 20 youtube videos

|                path|    modificationTime| length|
|--------------------|--------------------|-------|
|gs://dataproc-met...|2024-01-04 20:08:...|5051568|
|gs://dataproc-met...|2024-01-04 20:08:...|4450939|
|gs://dataproc-met...|2024-01-04 20:08:...|2766749|
|gs://dataproc-met...|2024-01-04 20:08:...|2525019|
|gs://dataproc-met...|2024-01-04 20:08:...|2311945|
|gs://dataproc-met...|2024-01-04 20:08:...|1682359|




