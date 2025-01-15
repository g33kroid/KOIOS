import argparse
import json
import os
import sys
from elasticsearch import Elasticsearch, helpers, ElasticsearchException
from elasticsearch.exceptions import NotFoundError, RequestError
import urllib3

# Suppress self-signed certificate warnings
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def parse_arguments():
    parser = argparse.ArgumentParser(description="Elasticsearch Script to manage index and push JSON data.")
    parser.add_argument(
        "--json_text",
        type=str,
        required=False,
        help="Optional JSON text to push to Elasticsearch."
    )
    parser.add_argument(
        "--index",
        type=str,
        required=True,
        help="Mandatory index name."
    )
    parser.add_argument(
        "--config_file",
        type=str,
        required=True,
        help="Mandatory configuration file containing Elasticsearch connection details."
    )
    return parser.parse_args()

def read_config(config_file):
    if not os.path.exists(config_file):
        print(f"Error: Config file '{config_file}' not found.")
        sys.exit(1)
    try:
        with open(config_file, "r") as file:
            config = json.load(file)
            return config
    except json.JSONDecodeError:
        print("Error: Failed to parse the configuration file. Ensure it is valid JSON.")
        sys.exit(1)

def connect_to_elasticsearch(config):
    try:
        es = Elasticsearch(
            hosts=[{"host": config["host"], "port": config["port"]}],
            http_auth=(config["username"], config["password"]),
            use_ssl=True,
            verify_certs=False
        )
        if not es.ping():
            print("Error: Unable to connect to Elasticsearch.")
            sys.exit(1)
        return es
    except ElasticsearchException as e:
        print(f"Error: Elasticsearch connection failed: {e}")
        sys.exit(1)

def create_index_if_not_exists(es, index_name):
    try:
        if not es.indices.exists(index=index_name):
            es.indices.create(index=index_name)
            print(f"Index '{index_name}' created.")
        else:
            print(f"Index '{index_name}' already exists.")
    except RequestError as e:
        print(f"Error: Failed to create index '{index_name}': {e}")
        sys.exit(1)
    except ElasticsearchException as e:
        print(f"Error: Elasticsearch error while checking/creating index: {e}")
        sys.exit(1)

def push_json_to_index(es, index_name, json_data):
    try:
        response = es.index(index=index_name, document=json_data)
        print(f"Document pushed to index '{index_name}'. Document ID: {response['_id']}")
        return response["_id"]
    except ElasticsearchException as e:
        print(f"Error: Failed to push JSON data to index '{index_name}': {e}")
        sys.exit(1)

def main():
    args = parse_arguments()

    # Read the config file
    config = read_config(args.config_file)

    # Connect to Elasticsearch
    es = connect_to_elasticsearch(config)

    # Create index if it doesn't exist
    create_index_if_not_exists(es, args.index)

    # Push JSON data if provided
    if args.json_text:
        try:
            json_data = json.loads(args.json_text)
        except json.JSONDecodeError:
            print("Error: Invalid JSON text provided.")
            sys.exit(1)
        push_json_to_index(es, args.index, json_data)
    else:
        print("No JSON text provided. Skipping data push.")

if __name__ == "__main__":
    main()