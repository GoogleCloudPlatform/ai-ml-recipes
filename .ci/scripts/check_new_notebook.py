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
from typing import Dict, List

INDEX_JSON_PATH = ".ci/index.json"
GITHUB_URL_PREFIX = "https://raw.githubusercontent.com/GoogleCloudPlatform/ai-ml-recipes/main"
EXCEPTIONS = [
	"https://raw.githubusercontent.com/GoogleCloudPlatform/ai-ml-recipes/main/public_datasets/bigframes/bigframes_quickstart.ipynb"
]

def read_json(path: str):

	with open(path, "r") as f:
		data = json.load(f)

	return data

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

def check_new_notebook(current_index_data: List):
	"""
	Checks if a new notebook entry is needed in index.json.
	"""
	current_urls = set([entry["url"] for entry in current_index_data])
	notebook_urls = []
	for filename in glob.iglob('**/*.ipynb', recursive=True):
		raw_url = f"{GITHUB_URL_PREFIX}/{filename}"
		notebook_urls.append(raw_url)

	return True if list(set(notebook_urls) - set(EXCEPTIONS) - current_urls) else False


if __name__ == "__main__":

	try:
		current_index_data = read_json(INDEX_JSON_PATH)

		if check_new_notebook(current_index_data):
			print("::set-output name=new_notebook::true")
		else:
			print("::set-output name=new_notebook::false")

	except Exception as e:
		raise e
