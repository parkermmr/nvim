from fastapi import FastAPI, HTTPException
from typing import Dict, Any
import os
import json
import requests

app = FastAPI()

OPENSEARCH_URL = 'http://localhost:9200'

@app.post("/create_index/{index_name}")
def create_index(index_name: str, schema: Dict[Any, Any]):
    """
    Create an index in OpenSearch with the given index_name and schema.

    @param index_name: The name of the index to create.
    @param schema: The schema to apply to the index.
    @return: Success message or error.
    """
    url = f"{OPENSEARCH_URL}/{index_name}"
    headers = {"Content-Type": "application/json"}

    response = requests.put(url, headers=headers, data=json.dumps(schema))
    if response.status_code in [200, 201]:
        return {"message": f"Index '{index_name}' created successfully."}
    else:
        raise HTTPException(status_code=response.status_code, detail=response.text)

def send_schemas_to_opensearch(schema_dir: str):
    """
    Send all schemas in the schema directory to OpenSearch, creating indices.

    @param schema_dir: The directory containing schema files.
    @return: None
    """
    for filename in os.listdir(schema_dir):
        if filename.endswith("_schema.json"):
            model_name = filename.split("_schema.json")[0]
            index_name = model_name.lower()
            schema_path = os.path.join(schema_dir, filename)
            with open(schema_path, 'r') as f:
                schema = json.load(f)
            url = f"{OPENSEARCH_URL}/{index_name}"
            headers = {"Content-Type": "application/json"}
            response = requests.put(url, headers=headers, data=json.dumps(schema))
            if response.status_code in [200, 201]:
                print(f"Index '{index_name}' created successfully.")
            else:
                print(f"Failed to create index '{index_name}': {response.status_code} {response.text}")

