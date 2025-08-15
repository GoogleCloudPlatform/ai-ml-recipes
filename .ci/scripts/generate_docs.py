import os
import json
import subprocess
from datetime import datetime
from google import genai
from google.genai import types

# The new SDK automatically picks up the GEMINI_API_KEY environment variable.
client = genai.Client()

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

def generate_metadata_with_ai(notebook_path, notebook_content, style_examples):
    """Uses AI to generate metadata from notebook content."""
    path_parts = notebook_path.split('/')
    category_from_path = path_parts[1] if len(path_parts) > 2 else None
    sub_category_from_path = path_parts[2] if len(path_parts) > 3 else None

    prompt = f"""
    Analyze the following Jupyter notebook content and extract the required metadata.
    Provide the output in a JSON format with the keys: "title", "description", "category", "sub_category", "main_technologies", "industry".

    **IMPORTANT RULES:**
    - The "category" MUST be: "{category_from_path}", but in Start Case
    - If a sub-category could be present in the path ("{sub_category_from_path}"), the "sub_category" should be that, but in Start Case.
    - If the sub-category from the path is "None" or empty, you MUST generate an appropriate "sub_category" based on the notebook's content, in Start Case.

    Follow the style and tone of the examples provided below.
    - title: A concise and descriptive title for the notebook.
    - description: A detailed summary of what the notebook does, the problem it solves, and the techniques used.
    - main_technologies: A comma-separated list of the primary technologies used (e.g., "PySpark, Gemini, BigQuery").
    - industry: The most related industry of the use case (e.g. Financial, Telecom, Retail, Gaming, Media & Entertainment, Mobility, Manufacturing, etc)

    Here are some examples of the desired output format and style:
    {style_examples}

    Now, analyze the following notebook content and generate the metadata according to the rules.
    Notebook Content:
    {notebook_content}
    """
    try:
        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=prompt,
            config=types.GenerateContentConfig(
                response_mime_type='application/json'
            )
        )
        return json.loads(response.text)
    except Exception as e:
        print(f"Error calling Generative AI model: {e}")
        return None

def update_index_json(new_entry):
    """Adds a new entry to .ci/index.json if it doesn't already exist."""
    index_path = '.ci/index.json'
    try:
        with open(index_path, 'r+', encoding='utf-8') as f:
            data = json.load(f)
            if not any(entry['url'].endswith(new_entry['url']) for entry in data):
                data.append(new_entry)
                f.seek(0)
                json.dump(data, f, indent=4)
                f.truncate()
                print(f"Updated {index_path} with new entry for {new_entry['title']}")
    except Exception as e:
        print(f"Error updating {index_path}: {e}")

def update_readme(new_entry):
    """Adds a new row to the correct table in README.md if it doesn't already exist."""
    readme_path = 'README.md'
    notebook_url = new_entry['url']
    
    try:
        with open(readme_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()

        # Check if the entry already exists
        if any(notebook_url in line for line in lines):
            print(f"Entry for {notebook_url} already exists. Skipping.")
            return

        # Find the table to insert into
        table_header = "| Title | Industry | Topic | Sub Topic | Main Technologies |"
        header_index = -1
        for i, line in enumerate(lines):
            if table_header in line:
                header_index = i
                break

        if header_index == -1:
            print(f"Error: Could not find the main notebook table in {readme_path}.")
            return

        # Find the end of the table (first blank line after the header and its separator)
        insert_index = header_index + 2  # Start searching after the header and separator line
        while insert_index < len(lines) and lines[insert_index].strip() != "":
            insert_index += 1

        # Create the new row
        new_row = (
            f"| [{new_entry['title']}]({notebook_url}) "
            f"| {new_entry.get('industry', 'N/A')} "
            f"| {new_entry.get('category', 'N/A')} "
            f"| {new_entry.get('sub_category', 'N/A')} "
            f"| {new_entry.get('main_technologies', 'N/A')} |\n"
        )

        # Insert the new row at the correct position
        lines.insert(insert_index, new_row)

        with open(readme_path, 'w', encoding='utf-8') as f:
            f.writelines(lines)
        
        print(f"Updated {readme_path} with new row for {new_entry['title']}")

    except Exception as e:
        print(f"Error updating {readme_path}: {e}")

def main():
    notebooks = get_changed_notebooks()
    if not notebooks:
        print("No new or modified notebooks found. Exiting.")
        return

    try:
        with open('.ci/index.json', 'r', encoding='utf-8') as f:
            style_examples = f.read()
    except Exception as e:
        print(f"Could not read .ci/index.json for style examples: {e}")
        style_examples = ""

    for notebook_path in notebooks:
        print(f"Processing notebook: {notebook_path}")
        content = json.dumps(json.load(open(notebook_path)))
        if not content:
            continue
        metadata_response = generate_metadata_with_ai(notebook_path, content, style_examples)
        if not metadata_response:
            print(f"Could not generate metadata for {notebook_path}. Skipping.")
            continue

        # Handle case where the AI returns a list with a single dictionary
        if isinstance(metadata_response, list) and len(metadata_response) > 0:
            metadata = metadata_response[0]
        elif isinstance(metadata_response, dict):
            metadata = metadata_response
        else:
            print(f"Unexpected metadata format for {notebook_path}: {metadata_response}")
            continue
        
        current_date = datetime.now().strftime("%m-%d-%Y")
        full_entry = {
            "title": metadata.get("title"),
            "description": metadata.get("description"),
            "category": metadata.get("category"),
            "sub_category": metadata.get("sub_category"),
            "url": f"https://raw.githubusercontent.com/GoogleCloudPlatform/ai-ml-recipes/main/{notebook_path}",
            "created_at": current_date
        }
        update_index_json(full_entry)
        
        readme_entry = full_entry.copy()
        readme_entry['url'] = f"./{notebook_path}"
        readme_entry['industry'] = metadata.get("industry")
        readme_entry['main_technologies'] = metadata.get("main_technologies")
        update_readme(readme_entry)

if __name__ == "__main__":
    main()
