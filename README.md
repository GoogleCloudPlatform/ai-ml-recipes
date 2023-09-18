# Dataproc Workspaces quickstart notebooks

Dataproc Workspaces quickstart notebooks are an effort to assist you to jumpstart the development of data processing and machine learning notebooks using [Dataproc](https://cloud.google.com/dataproc/)'s distributed processing capabilities.

[![Open in Cloud Shell](http://gstatic.com/cloudssh/images/open-btn.svg)](https://console.cloud.google.com/cloudshell/editor)

## Notebooks
Please refer to each notebooks folder documentation for more information:

* Public Datasets
  * Dataproc Metastore
    * [Metastore Public Datasets quickstart](./public_datasets/dataproc_metastore/metastore_public_datasets_quickstart.ipynb)
* Summarization
  * Large PDF documents
    * [OCR and PDF summarization using LLM](./summarization/large_pdf_documents/ocr_contract_summarization_llm.ipynb)
* Regression
  * Decision Tree Regression
    * [Housing Prices Prediction](./regression/decision_tree_regression/housing_prices_prediction.ipynb)
  * Random Forest Regression
    * [Bike Trip Duration Prediction](./regression/random_forest_regression/bike_trip_duration_prediction.ipynb)

## Getting Started 

1) Install [gcloud cli](https://cloud.google.com/sdk/docs/install)
2) Clone this repository by running  
     ```git clone https://github.com/GoogleCloudPlatform/dataproc-workspaces-notebooks.git```
3) Setup your local environment by installing the packages in requirements.txt
4) Option 1) Create a Dataproc Serverless Notebooks, after creating a Runtime Template with your desired Dataproc config, and use it as a Jupyter kernel  
   Option 2) Create a Dataproc Cluster with your desired Dataproc config, and use it as a Jupyter kernel  
   Option 3) Create a Dataproc Workspaces environment using the Console UI  

## Contributing
See the contributing [instructions](./CONTRIBUTING.md) to get started contributing.

## License
All solutions within this repository are provided under the [Apache 2.0](https://www.apache.org/licenses/LICENSE-2.0) license. Please see the [LICENSE](/LICENSE) file for more detailed terms and conditions.

## Disclaimer
This repository and its contents are not an official Google Product.

## Contact
Questions, issues, and comments can be raised via Github issues.
