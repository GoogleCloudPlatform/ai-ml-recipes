# Copyright 2023 Google LLC
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

import json
import glob
import argparse
import sys
from typing import Dict, List, Set

GITHUB_URL_PREFIX = "https://raw.githubusercontent.com/GoogleCloudPlatform/ai-ml-recipes/main"


def read_json(path) -> List[Dict]:
    with open(path, "r") as f:
        data = json.load(f)  # This will raise an error if JSON is invalid
    return data


def get_notebook_urls() -> Set[str]:
    """
    Gets the raw URLs of all .ipynb files in the repository,
    using the provided GitHub URL prefix.
    """
    notebook_urls = []
    for filename in glob.iglob('**/*.ipynb', recursive=True):
        # Construct the raw URL using the prefix and local path
        raw_url = f"{GITHUB_URL_PREFIX}/{filename}"
        notebook_urls.append(raw_url)
    return set(notebook_urls)


def validate_index_json(notebook_urls: Set[str], current_index_data: List[Dict], allow_subset: bool = False):
    """
    Validates that the index JSON file contains valid entries.

    Args:
        notebook_urls: A set of all valid notebook URLs in the repo.
        current_index_data: The data loaded from the JSON file.
        allow_subset: If True, the JSON file does not need to contain all notebooks.
    """
    
    # Check for uniqueness
    current_urls_in_index = [entry["url"] for entry in current_index_data]
    if len(current_urls_in_index) != len(set(current_urls_in_index)):
        raise ValueError(f"URLs are not unique in the provided JSON file.")

    # Check validity: Every URL in the index MUST exist in the repo 
    for entry in current_index_data:
        url = entry.get("url")
        if not url:
             raise ValueError(f"Entry missing 'url' field: {entry}")
        
        if url not in notebook_urls:
             raise ValueError(f"URL in index does not match any existing notebook in the repo: {url}")

    # Check completeness: Every notebook in the repo MUST be in the index (unless allow_subset is True)
    if not allow_subset:
        index_urls_set = set(current_urls_in_index)
        missing_urls = notebook_urls - index_urls_set
        if missing_urls:
            raise ValueError(f"Missing entries for notebooks: {missing_urls}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Validate index JSON files.")
    parser.add_argument("--file", default=".ci/index.json", help="Path to the JSON file to validate.")
    parser.add_argument("--allow-subset", action="store_true", help="Allow the JSON file to contain a subset of all notebooks.")
    
    args = parser.parse_args()

    try:
        notebook_urls = get_notebook_urls()
        current_index_data = read_json(args.file)
        validate_index_json(notebook_urls, current_index_data, args.allow_subset)
        print(f"Validation successful for {args.file}")

    except Exception as e:
        print(f"Validation failed: {e}")
        sys.exit(1)
