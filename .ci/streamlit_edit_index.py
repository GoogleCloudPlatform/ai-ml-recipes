import streamlit as st
import json
from datetime import datetime

def load_data(filepath):
  """Loads data from a JSON file and converts 'created_at' to datetime."""
  with open(filepath, "r") as f:
    data = json.load(f)
  for row in data:
    if row['created_at']:
      row['created_at'] = datetime.strptime(row['created_at'], "%m-%d-%Y").date()
  return data

def save_data(filepath, data):
  """Saves data to a JSON file, converting 'created_at' back to strings."""
  for row in data:
    if row['created_at']:
      row['created_at'] = row['created_at'].strftime("%m-%d-%Y")
  with open(filepath, "w") as f:
    json.dump(data, f, indent=4)

def main():

  st.set_page_config(page_title="Edit index.json", layout="wide", initial_sidebar_state="expanded")
  st.title("Interface to edit index.json file")

  # Load data from the JSON file
  filepath = ".ci/index.json"
  data = load_data(filepath)


  # Display the data in a Streamlit data editor
  edited_data = st.data_editor(data,
                               use_container_width=True,
                               hide_index=True,
                               num_rows="dynamic",
                               column_config={
                                   "created_at": st.column_config.DateColumn(
                                       "Created At",
                                       format="MM-DD-YYYY",
                                       step=1,
                                   )
                               })

  # Save the edited data if changes were made
  if edited_data != data:
    save_data(filepath, edited_data)
    st.success("Data saved successfully!")

if __name__ == "__main__":
  main()