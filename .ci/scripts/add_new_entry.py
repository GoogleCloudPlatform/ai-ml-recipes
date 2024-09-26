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


import sys
import json
import glob
from typing import Dict, List

from datetime import datetime

INDEX_JSON_PATH = ".ci/index.json"
GITHUB_URL_PREFIX = "https://raw.githubusercontent.com/GoogleCloudPlatform/ai-ml-recipes/main"
EXCEPTIONS = [
    "https://raw.githubusercontent.com/GoogleCloudPlatform/ai-ml-recipes/main/public_datasets/bigframes/bigframes_quickstart.ipynb"
]

def read_json(path: str):

    with open(path, "r") as f:
        data = json.load(f)

    return data

def save_json(path: str, data: List):

    with open(path, "w") as f:
        json.dump(data, f, indent=4)

def get_notebook_urls_diff(current_index_data: List):
    """
    Gets the raw URLs of all .ipynb files in the repository which are not in index.json file
    """

    current_urls = set([entry["url"] for entry in current_index_data])
    notebook_urls = []
    for filename in glob.iglob('**/*.ipynb', recursive=True):
        raw_url = f"{GITHUB_URL_PREFIX}/{filename}"
        notebook_urls.append(raw_url)

    return list(set(notebook_urls) - set(EXCEPTIONS) - current_urls)

if __name__ == "__main__":

    try:
        current_index_data = read_json(INDEX_JSON_PATH)

        if len(sys.argv) != 5:
            raise Exception("You should provide: title, description, category and sub_category as sys args")

        notebooks_to_add = get_notebook_urls_diff(current_index_data)

        if len(notebooks_to_add) == 1:
            new_entry_metadata = {
                "title": sys.argv[1],
                "description": sys.argv[2],
                "category": sys.argv[3],
                "sub_category": sys.argv[4],
                "url": notebooks_to_add[0],
                "created_at": datetime.today().strftime('%m-%d-%Y')
            }
            current_index_data.append(new_entry_metadata)
            save_json(INDEX_JSON_PATH, current_index_data)
        else:
            raise Exception("Please add only one notebook per Pull Request")

    except Exception as e:
        raise e
