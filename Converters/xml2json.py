#!/usr/bin/env python3
import json
import xmltodict
import argparse
import sys

def convert_xml_to_json(xml_path, output_path=None):
    """Convert XML file to JSON using xmltodict."""
    try:
        # Read XML file
        with open(xml_path, 'r') as xml_file:
            xml_content = xml_file.read()
        
        # Parse XML to dict and convert to JSON
        json_data = json.dumps(xmltodict.parse(xml_content), indent=4, sort_keys=True)
        
        # Handle output
        if output_path:
            with open(output_path, 'w') as json_file:
                json_file.write(json_data)
            print(f"JSON data has been written to {output_path}")
        else:
            print(json_data)
            
    except FileNotFoundError:
        print(f"Error: File '{xml_path}' not found")
        sys.exit(1)
    except Exception as e:
        print(f"Error: {str(e)}")
        sys.exit(1)

def main():
    # Set up argument parser
    parser = argparse.ArgumentParser(description='Convert XML file to JSON using xmltodict')
    parser.add_argument('xml_path', help='Path to the XML file')
    parser.add_argument('-o', '--output', help='Output JSON file path (optional)')
    
    # Parse arguments
    args = parser.parse_args()
    
    # Convert XML to JSON
    convert_xml_to_json(args.xml_path, args.output)

if __name__ == "__main__":
    main()
