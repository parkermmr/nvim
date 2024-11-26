import argparse
import os
import importlib.util
import json
import sys
from pydantic import BaseModel
from typing import get_origin, get_args, Union
import inspect
from copy import deepcopy
import datetime
from enum import Enum

def get_os_type(python_type):
    """
    Map Python types to OpenSearch types.

    @param python_type: The Python type to map.
    @return: A dictionary representing the OpenSearch field type.
    """
    origin = get_origin(python_type)
    args = get_args(python_type)

    if origin is Union:
        non_none_types = [arg for arg in args if arg is not type(None)]
        if non_none_types:
            return get_os_type(non_none_types[0])
        else:
            return {'type': 'text'}
    elif origin is list:
        item_type = args[0]
        os_type = get_os_type(item_type)
        return {
            'type': 'nested',
            'properties': os_type.get('properties', {'value': os_type})
        }
    elif origin is dict:
        return {'type': 'object'}
    elif inspect.isclass(python_type) and issubclass(python_type, BaseModel):
        return {
            'type': 'object',
            'properties': get_properties_from_model(python_type)
        }
    elif inspect.isclass(python_type) and issubclass(python_type, Enum):
        return {
            'type': 'keyword'
        }
    else:
        if python_type == str:
            return {'type': 'text'}
        elif python_type == int:
            return {'type': 'integer'}
        elif python_type == float:
            return {'type': 'float'}
        elif python_type == bool:
            return {'type': 'boolean'}
        elif python_type == datetime.datetime:
            return {
                'type': 'date',
                'format': 'strict_date_optional_time||epoch_millis'
            }
        else:
            return {'type': 'text'}

def get_properties_from_model(model):
    """
    Generate the 'properties' dictionary for a given Pydantic model.

    @param model: The Pydantic model class.
    @return: A dictionary of properties for OpenSearch mapping.
    """
    properties = {}
    fields = model.model_fields

    for field_name, field in fields.items():
        field_type = field.annotation
        field_properties = get_os_type(field_type)

        if field_properties.get('type') == 'text' and field_name not in ['Description', 'Category']:
            field_properties['analyzer'] = 'substring_search'
            field_properties['search_analyzer'] = 'substring_search'

        if field_name.lower() == 'uuid':
            field_properties['type'] = 'keyword'

        if field_properties.get('type') == 'date':
            field_properties['format'] = 'strict_date_optional_time||epoch_millis'

        properties[field_name] = field_properties

    return properties

def main():
    """
    Main function to convert Pydantic models to OpenSearch schemas.

    @return: None
    """
    parser = argparse.ArgumentParser(description='Convert Pydantic models to OpenSearch schemas.')
    parser.add_argument('input_file', help='The Python file containing Pydantic models.')
    parser.add_argument('-o', '--output_dir', default='schemas', help='The output directory for schema files.')

    args = parser.parse_args()
    input_file = args.input_file
    output_dir = args.output_dir

    os.makedirs(output_dir, exist_ok=True)

    spec = importlib.util.spec_from_file_location("models_module", input_file)
    models_module = importlib.util.module_from_spec(spec)
    sys.modules["models_module"] = models_module
    spec.loader.exec_module(models_module)

    schema_template = {
        "settings": {
            "index": {
                "number_of_shards": 1,
                "number_of_replicas": 1
            },
            "analysis": {
                "analyzer": {
                    "substring_search": {
                        "tokenizer": "substring_tokenizer",
                        "filter": ["lowercase"]
                    }
                },
                "tokenizer": {
                    "substring_tokenizer": {
                        "type": "ngram",
                        "min_gram": 3,
                        "max_gram": 3
                    }
                }
            }
        },
        "mappings": {
            "properties": {}
        }
    }

    for attr_name in dir(models_module):
        attr = getattr(models_module, attr_name)
        if inspect.isclass(attr) and issubclass(attr, BaseModel) and attr.__module__ == models_module.__name__:
            model = attr
            model_name = model.__name__.lower()

            properties = get_properties_from_model(model)

            schema = deepcopy(schema_template)
            schema['mappings']['properties'] = properties

            output_file = os.path.join(output_dir, f'{model_name}_schema.json')
            with open(output_file, 'w') as f:
                json.dump(schema, f, indent=2)
            print(f'Schema for {model_name} written to {output_file}')

if __name__ == '__main__':
    main()
