import os
import json
import subprocess
from google import genai
from google.genai import types

# The new SDK automatically picks up the GEMINI_API_KEY environment variable.
client = genai.Client()

APACHE_LICENSE_TEXT = """
# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""

def get_changed_notebooks():
    """
    Identifies newly added notebooks.
    - In a GitHub Action, it compares the current branch to the base branch for added files.
    - When run locally, it checks for newly added files in the git staging area.
    """
    # Check if running in a GitHub Action PR context
    if os.getenv('GITHUB_BASE_REF'):
        print("Running in GitHub Actions context. Comparing with base branch for new files.")
        base_ref = os.getenv('GITHUB_BASE_REF', 'main')
        # --diff-filter=A selects only new files (Added)
        command = ['git', 'diff', '--name-only', '--diff-filter=A', f'origin/{base_ref}...HEAD']
    else:
        print("Running in local context. Checking git staging area for new files.")
        # --diff-filter=A selects only new files (Added) from the staging area
        command = ['git', 'diff', '--name-only', '--diff-filter=A', '--cached']

    try:
        result = subprocess.run(
            command,
            capture_output=True,
            text=True,
            check=True
        )
        # Filter out empty strings that can result from the split
        added_files = [f for f in result.stdout.strip().split('\n') if f]
        return [f for f in added_files if f.startswith('notebooks/') and f.endswith('.ipynb')]
    except subprocess.CalledProcessError as e:
        # This can happen if there are no changes, which is not an error.
        print(f"Git diff command returned non-zero status, likely no new files: {e.stderr}")
        return []
    except FileNotFoundError:
        print("Error: git command not found. Is git installed and in your PATH?")
        return []

def generate_platform_links_html(notebook_path):
    """Generates the HTML table for platform links."""
    base_url = "https://github.com/GoogleCloudPlatform/ai-ml-recipes/blob/main/"
    raw_base_url = "https://raw.githubusercontent.com/GoogleCloudPlatform/ai-ml-recipes/main/"
    
    colab_url = f"https://colab.research.google.com/github/GoogleCloudPlatform/ai-ml-recipes/blob/main/{notebook_path}"
    github_url = f"{base_url}{notebook_path}"
    vertex_url = f"https://console.cloud.google.com/vertex-ai/workbench/deploy-notebook?download_url={raw_base_url}{notebook_path}"
    bq_studio_url = f"https://console.cloud.google.com/bigquery/import?url={github_url}"
    colab_enterprise_url = f"https://console.cloud.google.com/vertex-ai/colab/import/https:%2F%2Fraw.githubusercontent.com%2FGoogleCloudPlatform%2Fai-ml-recipes%2Fmain%2F{notebook_path}"

    return f"""<table align="left">
  <td><a href="{colab_url}"><img src="https://avatars.githubusercontent.com/u/33467679?s=200&v=4" width="32px" alt="Colab logo"> Run in Colab</a></td>
  <td><a href="{github_url}"><img src="https://github.githubassets.com/assets/GitHub-Mark-ea2971cee799.png" width="32px" alt="GitHub logo"> View on GitHub</a></td>
  <td><a href="{vertex_url}"><img src="https://lh3.googleusercontent.com/UiNooY4LUgW_oTvpsNhPpQzsstV5W8F7rYgxgGBD85cWJoLmrOzhVs_ksK_vgx40SHs7jCqkTkCk=e14-rj-sc0xffffff-h130-w32" alt="Vertex AI logo"> Open in Vertex AI Workbench</a></td>
  <td><a href="{bq_studio_url}"><img src="https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTW1gvOovVlbZAIZylUtf5Iu8-693qS1w5NJw&s" alt="BQ logo" width="35"> Open in BQ Studio</a></td>
  <td><a href="{colab_enterprise_url}"><img width="32px" src="https://lh3.googleusercontent.com/JmcxdQi-qOpctIvWKgPtrzZdJJK-J3sWE1RsfjZNwshCFgE_9fULcNpuXYTilIR2hjwN" alt="Google Cloud Colab Enterprise logo"> Open in Colab Enterprise</a></td>
</table>"""

def enhance_notebook(notebook_path):
    """Reads, enhances, and overwrites a notebook file."""
    print(f"--- Starting enhancement for {notebook_path} ---")
    try:
        with open(notebook_path, 'r', encoding='utf-8') as f:
            original_notebook_json = json.load(f)
        print("  - Successfully read and parsed the notebook.")
    except Exception as e:
        print(f"  - Error reading or parsing notebook {notebook_path}: {e}")
        return

    original_content_str = json.dumps(original_notebook_json, indent=2)
    standard_links_html = generate_platform_links_html(notebook_path)
    print("  - Generated dynamic platform links HTML.")

    prompt = f"""
    Analyze the following Jupyter notebook content. Your task is to ensure it meets our repository's standards.
    1.  **Apache 2.0 License**: Check if the first cell is a code cell containing the Apache 2.0 license. If it is missing (only in this situation), add the following license text as the very first cell.
        ```python
        {APACHE_LICENSE_TEXT}
        ```
    2.  **Standard Links**: Check if a markdown cell containing the standard platform links table exists, and it correctly references the notebook. If not, only in this situation, add the following HTML block as a markdown cell after the license cell.
        ```markdown
        {standard_links_html}
        ```
    3.  **Documentation Quality**: Review the entire notebook. Ensure that every code cell is preceded by a markdown cell that clearly explains what the code does.
    If you find code cells without proper explanation, generate and insert a concise, well-written markdown cell before them.
    
    If not, and only then, add documentation markdown cells:
     - Evaluate if the markdown cell text have should have a prefix to be a title (#), a subtitle (##), a subsubtitle (###), a subsubsubtitle (####) or normal text.
     - The notebook should definitely have a title, an overview section and a setup and imports sections at least.
     - Return the entire, corrected notebook as a single, valid JSON object, with no other text or explanations in your response.

    Original Notebook Content:
    {original_content_str}
    """
    print("  - Constructed prompt for the generative AI model.")

    try:
        print("  - Sending request to the generative AI model...")
        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=prompt,
            config=types.GenerateContentConfig(
                response_mime_type='application/json'
            )
        )
        print("  - Received response from the model.")
        
        cleaned_response_text = response.text.strip().replace("```json", "").replace("```", "").strip()
        enhanced_notebook_json = json.loads(cleaned_response_text)
        enhanced_content_str = json.dumps(enhanced_notebook_json, indent=2)

        if original_content_str == enhanced_content_str:
            print("  - No changes detected. Notebook is already compliant.")
        else:
            print("  - Enhancements were made by the AI. Overwriting the notebook file.")
            with open(notebook_path, 'w', encoding='utf-8') as f:
                f.write(enhanced_content_str)
            print(f"  - Successfully enhanced and overwrote notebook: {notebook_path}")

    except Exception as e:
        print(f"  - Error during AI enhancement for {notebook_path}: {e}")
        if 'response' in locals():
            print(f"  - AI Response was: {response.text}")
    print(f"--- Finished enhancement for {notebook_path} ---\n")

def main():
    notebooks_to_process = get_changed_notebooks()
    if not notebooks_to_process:
        print("No new or modified notebooks found to enhance.")
        return
    
    print(f"\nFound {len(notebooks_to_process)} notebook(s) to process: {notebooks_to_process}\n")

    for notebook in notebooks_to_process:
        enhance_notebook(notebook)

if __name__ == "__main__":
    main()
