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

### Contribution Workflow for New Notebooks

We have an AI-powered workflow to help streamline the contribution process. You can either use the automated scripts locally or let the GitHub Actions workflow handle the heavy lifting for you.

#### Step 1: Develop Your Notebook

-   Create your notebook using PySpark or BigQuery DataFrames.
-   Focus on the logic and the value of your recipe. You can follow the general structure of existing notebooks (Overview, Setup, EDA, Modeling, etc.), but don't worry if you forget to add the license header or platform links—the AI will handle it.
-   Place your finished notebook file in the appropriate `notebooks/<category>/<sub_category>/` folder. The folder structure is crucial as it helps the AI determine the correct metadata.

#### Step 2: Run the AI-Powered Scripts (Recommended Local Method)

This is the easiest way to ensure your contribution is compliant and well-documented.

1.  **Set up your API Key**: Make sure you have a Gemini API key and have set it as an environment variable:
    ```bash
    export GEMINI_API_KEY="YOUR_API_KEY"
    ```
2.  **Stage your new notebook**: Use `git` to add your new notebook file to the staging area.
    ```bash
    git add notebooks/<category>/<sub_category>/your_new_notebook.ipynb
    ```
3.  **Run the Enhancement Script**: This script will standardize your notebook by adding the license, platform links, and improving documentation where needed.
    ```bash
    python .ci/scripts/enhance_notebook.py
    ```
4.  **Run the Documentation Script**: This script will generate the metadata for your notebook and automatically update the `.ci/index.json` and `README.md` files.
    ```bash
    python .ci/scripts/generate_docs.py
    ```
5.  **Commit all changes**: Add all the files that were created or modified by the scripts and commit them.
    ```bash
    git add .
    git commit -m "feat: Add new notebook for X"
    ```

#### Step 3: Create a Pull Request

-   Create a Pull Request from your `feat/<new_notebook>` branch to the `main` branch.
-   The PR title should follow the [Conventional Commits](https://www.conventionalcommits.org/) specification (e.g., `feat: Add housing price prediction notebook`).

### The Automated CI/CD Workflow

When you create a pull request, our GitHub Actions workflow will automatically perform the following steps:

1.  **Validation**: It first runs the `.ci/scripts/validate_entries.py` script to validate `index.json` and `samples.json`.
2.  **AI-Powered Autofix (If Validation Fails)**: If the validation fails (e.g., you forgot to run the scripts locally), the `autofix-docs` job will be triggered. This job:
    -   Runs the **enhancement script** to standardize your notebook.
    -   Runs the **documentation script** to generate and add the required metadata to `index.json` and `README.md`.
    -   Commits these changes directly to your pull request branch. The validation will then re-run and should pass.

### Manual Contribution (For Reference)

If you prefer to do things manually, you will need to:
1.  Add the Apache 2.0 license and the platform links table to your notebook.
2.  Add a new entry for your notebook to the `.ci/index.json` file.
3.  Add a new row for your notebook to the table in the `README.md` file.
4.  Run `.ci/scripts/validate_entries.py` to confirm your `index.json` changes are valid.

Type |	Title	| Description  |
----- |---------| ------------- |
feat |	Features	| A new feature or notebook.  |
fix |	Bug Fixes	| A bug fix.  |
docs |	Documentation	| Changes to documentation only (e.g., README, API docs).  |
style |	Styles	| Code style changes that do not affect the meaning of the code (e.g., white-space, formatting, missing semi-colons).  |
refactor |	Code Refactoring	| A code change that neither fixes a bug nor adds a feature.  |
perf |	Performance	| A code change that improves performance.  |
test |	Tests	| Adding missing tests or correcting existing tests.  |
chore |	Chores	| Changes to the build process, auxiliary tools, or configurations that don't relate to production code.  |
build |	Build System	| Changes that affect the build system or external dependencies.  |
ci |	Continuous Integration	| Changes to CI configuration files and scripts (e.g., GitHub Actions).  |
revert |	Reverts	| Reverts a previous commit.  |

### Community Guidelines

This project follows
[Google's Open Source Community Guidelines](https://opensource.google/conduct/).
