import subprocess
import argparse
import json

def json_pretty(sub_output):
    # The byte string input
    byte_string = sub_output
    # Step 1: Decode the byte string
    decoded_string = byte_string.decode('utf-8')

    # Step 2: Split into individual JSON objects
    json_strings = decoded_string.strip().split('\n')

    # Step 3: Parse each JSON object into a dictionary
    json_objects = [json.loads(js) for js in json_strings]

    # Step 4: Create a unified JSON structure (list of dictionaries)
    unified_json = json_objects

    # Return the unified JSON
    return json.dumps(unified_json, indent=4)

# Set up argument parser
parser = argparse.ArgumentParser()
parser.add_argument("-ip", help="IP Address")
args = parser.parse_args()

# Check if the IP argument is provided
if not args.ip:
    parser.print_help()
    exit(1)

ip = args.ip

try:
    out = subprocess.check_output(f"/home/hunter/go/bin/subfinder -d {ip} --all -recursive -oJ", shell=True)
    sub_list = json_pretty(out)
    print(sub_list)

except subprocess.CalledProcessError as e:
    print(e)
