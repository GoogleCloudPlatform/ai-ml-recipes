import json
import glob

EXCEPTIONS = [
    "https://raw.githubusercontent.com/GoogleCloudPlatform/ai-ml-recipes/main/public_datasets/bigframes/bigframes_quickstart.ipynb"
]


def get_notebook_urls():
  """
  Gets the raw URLs of all .ipynb files in the repository,
  using the provided GitHub URL prefix.
  """
  github_url_prefix = "https://raw.githubusercontent.com/GoogleCloudPlatform/ai-ml-recipes/main"
  notebook_urls = []
  for filename in glob.iglob('**/*.ipynb', recursive=True):
    # Construct the raw URL using the prefix and local path
    raw_url = f"{github_url_prefix}/{filename}"
    notebook_urls.append(raw_url)
  return list(set(notebook_urls) - set(EXCEPTIONS))


def validate_index_json(notebook_urls):
  """
  Validates that index.json contains entries for all notebook URLs
  and has valid JSON format.
  """
  try:
    # Validate JSON format and load the data
    with open(".ci/index.json", "r") as f:
      index_data = json.load(f)  # This will raise an error if JSON is invalid

    # Proceed with entry validation
    for url in notebook_urls:
      found = False
      for entry in index_data:
        if entry["url"] == url:
          found = True
          break
      if not found:
        raise ValueError(f"Missing entry for notebook: {url}")

  except json.JSONDecodeError as e:  # Catch JSON decoding errors
    raise ValueError(f"Invalid JSON format: {e}")
  except Exception as e:
    raise e


if __name__ == "__main__":
  notebook_urls = get_notebook_urls()
  validate_index_json(notebook_urls)
