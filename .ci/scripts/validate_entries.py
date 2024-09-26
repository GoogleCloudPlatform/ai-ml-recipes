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


def read_json(path):
	with open(path, "r") as f:
		data = json.load(f)  # This will raise an error if JSON is invalid

	return data


def get_notebook_urls():
	"""
	Gets the raw URLs of all .ipynb files in the repository,
	using the provided GitHub URL prefix.
	"""
	notebook_urls = []
	for filename in glob.iglob('**/*.ipynb', recursive=True):
		# Construct the raw URL using the prefix and local path
		raw_url = f"{GITHUB_URL_PREFIX}/{filename}"
		notebook_urls.append(raw_url)
	return list(set(notebook_urls) - set(EXCEPTIONS))


def validate_index_json(notebook_urls: List, current_index_data: List):
	"""
	Validates that index.json contains entries for all notebook URLs
	and has valid JSON format.
	"""
	for url in notebook_urls:
		found = False
		for entry in current_index_data:
			if entry["url"] == url:
				found = True
				break
		if not found:
			raise ValueError(f"Missing entry for notebook: {url}")

	current_urls_in_index = [entry["url"] for entry in current_index_data]
	if len(current_urls_in_index) != len(set(current_urls_in_index)):
		raise ValueError(f"URLs are not unique in index.json")


if __name__ == "__main__":

	try:
		notebook_urls = get_notebook_urls()
		current_index_data = read_json(INDEX_JSON_PATH)
		validate_index_json(notebook_urls, current_index_data)

	except Exception as e:
		raise e
