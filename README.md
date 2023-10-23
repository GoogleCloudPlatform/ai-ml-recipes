# Dataproc ML Quickstart Notebooks

Dataproc ML Quickstart Notebooks are an effort to assist you to jumpstart the development of data processing and machine learning notebooks using [Dataproc](https://cloud.google.com/dataproc/)'s distributed processing capabilities.  

We are release a set of machine learning focused notebooks, for you to adapt, extend, and use to solve your use cases using your own data.  
Also, we are releasing a public read-only Dataproc Metastore, for you to easily have access to several curated public datasets in this managed metastore using Spark.  

[![Open in Cloud Shell](http://gstatic.com/cloudssh/images/open-btn.svg)](https://console.cloud.google.com/cloudshell/editor)

## Public Datasets
Please refer to [Metastore Public Datasets quickstart](./public_datasets/dataproc_metastore/metastore_public_datasets_quickstart.ipynb) to learn how you can quickly integrate your Spark application with a managed Dataproc Metastore and use one of our curated public datasets. Later on, you will be able to create your own Dataproc Metastore and centralize your own datasets.

## Notebooks
Please refer to each notebooks folder documentation for more information:
* Classification
    * Logistic Regression
        * [Wine Quality Classification](./classification/logistic_regression/wine_quality_classification_mlr.ipynb)
    * Multilayer Perceptron Classifier
        * [SMS Spam Filtering](./classification/multilayer_perceptron_classifier/sms_spam_filtering.ipynb)
* Regression
  * Decision Tree Regression
    * [Housing Prices Prediction](./regression/decision_tree_regression/housing_prices_prediction.ipynb)
  * Random Forest Regression
    * [Bike Trip Duration Prediction](./regression/random_forest_regression/bike_trip_duration_prediction.ipynb)
* Summarization
    * Large PDF documents
        * [OCR and PDF summarization using LLM](./summarization/large_pdf_documents/ocr_contract_summarization_llm.ipynb)
* Sampling
  * Monte Carlo method
    * [HCustomer Price Index simulation](./sampling/monte_carlo/customer_price_index.ipynb)

### Dataproc Jupyter Plugin

We recommend leveraging the [Dataproc Jupyter Plugin](https://github.com/GoogleCloudDataproc/dataproc-jupyter-plugin), which will be available in your local environment just by installing the dependency running ```pip install -r requirements.txt```. This will enable you to:

- Connect your Jupyterlab notebooks from anywhere to Dataproc
- Develop in Python, SQL, Java/Scala, and R
- Get started within minutes with minimal setup
- Troubleshoot your Spark code inside Jupyterlab
- Manage Dataproc clusters and jobs
- Run notebooks in your favorite IDE that supports Jupyter using Dataproc as kernel

## Getting Started 

1) Install [gcloud cli](https://cloud.google.com/sdk/docs/install)
2) Run ```gclout init``` to setup your default GCP configuration
3) Clone this repository by running  
     ```git clone https://github.com/GoogleCloudPlatform/dataproc-ml-quickstart-notebooks.git```
4) Install requirements by running ```pip install -r requirements.txt```
5) Start running the notebooks using one of the approaches:  
   5.1) Dataproc Jupyter Plugin - Create a Dataproc Serverless Notebooks, after creating a Runtime Template with your desired Dataproc config, and use it as a Jupyter kernel when executing the notebooks    
   5.2) Dataproc Jupyter Plugin - Create a Dataproc Cluster with your desired Dataproc config, and use it as a Jupyter kernel when executing the notebooks  
   5.3) Dataproc Workspaces - Create a Dataproc Workspaces environment using the Console UI  

## Contributing
See the contributing [instructions](./CONTRIBUTING.md) to get started contributing.

## License
All solutions within this repository are provided under the [Apache 2.0](https://www.apache.org/licenses/LICENSE-2.0) license. Please see the [LICENSE](/LICENSE) file for more detailed terms and conditions.

## Disclaimer
This repository and its contents are not an official Google Product.

## Contact
Questions, issues, and comments can be raised via Github issues.
