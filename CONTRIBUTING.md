# How to Contribute

We'd love to accept your patches and contributions to this project. There are
just a few small guidelines you need to follow.

#### Contributor License Agreement

Contributions to this project must be accompanied by a Contributor License
Agreement (CLA). You (or your employer) retain the copyright to your
contribution; this simply gives us permission to use and redistribute your
contributions as part of the project. Head over to
<https://cla.developers.google.com/> to see your current agreements on file or
to sign a new one.

You generally only need to submit a CLA once, so if you've already submitted one
(even if it was for a different project), you probably don't need to do it
again.

### Code Reviews

All submissions, including submissions by project members, require review.   
We use GitHub pull requests for this purpose.  
Consult [GitHub Help](https://help.github.com/articles/about-pull-requests/) for more
information on using pull requests.

### Suggested guidelines to add a new notebook

Here are some suggested guidelines for a pull request of a new notebook:

0) **Check the [README](./README.md) file to setup your development environment** 

1) **Develop a new notebook using PySpark or [BigQuery Dataframes](https://cloud.google.com/python/docs/reference/bigframes/latest)**
   1) The first cell of the notebook should be the Apache 2.0 license header
   2) Following sections should be similar to, but not necessarily, like this:
      1) Overview of the notebook
      2) IAM configuration needed to run on GCP
      3) Importing dependencies
      4) Setup e.g creating Spark session
      5) Reading the dataset from BigQuery or GCS bucket
      6) Exploratory data analysis
      7) Training / Evaluating / Predicting using an ML model or pretrained ML model
      8) Demonstrating results
   3) Clear notebook cell outputs before commit
   4) Show table schemas or examples ot facilitate understanding

2) **To make your notebook appear on Vertex AI Workbench, run the script to add its reference to the index.json file**    
    ```python .ci/scripts/add_new_entry.py <NOTEBOOK_TITLE> <NOTEBOOK_DESCRIPTION> <NOTEBOOK_CATEGORY> <NOTEBOOK_SUBCATEGORY>```   
    This script will automatically add a new entry to the .ci/index.json file with the correct url reference and the current date  
    Take a look at the .ci/index.json file to see examples of how to write the necessary fields  

3) **Make sure to put you notebook file under the correct category and sub_category subfolders**  
   As you can see in the repo, we already have some categories and subcategory folders under the notebooks folder, such as:
      1) classification -> logistic_regression
      2) regression -> decision_tree_regression
      3) generative_ai -> content_generation

4) **Run ```python .ci/scripts/validate_entries.py``` to make sure the added notebook is correctly added to index.json file**  
   This script will be executed by Github Actions workflow upon a PR

### Community Guidelines

This project follows
[Google's Open Source Community Guidelines](https://opensource.google/conduct/).