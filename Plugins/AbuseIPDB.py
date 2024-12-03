import argparse
import json
import requests
import logging

# Configure logging
logging.basicConfig(filename='abuseipdb.log', level=logging.INFO, 
                    format='%(asctime)s - %(levelname)s - %(message)s')

def query_abuseipdb(ip, api_key):
    url = f'https://api.abuseipdb.com/api/v2/check'
    headers = {
        'Accept': 'application/json',
        'Key': api_key
    }
    params = {
        'ipAddress': ip,
        'maxAgeInDays': 90
    }
    try:
        response = requests.get(url, headers=headers, params=params)
        response.raise_for_status()
        return response.json()
    except requests.RequestException as e:
        logging.error(f"Failed to query AbuseIPDB for {ip}: {e}")
        return {"error": f"Failed to query AbuseIPDB for {ip}"}

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Query IP reputation from AbuseIPDB")
    parser.add_argument("ip", help="IP address to check")
    parser.add_argument("api_key", help="AbuseIPDB API key")
    args = parser.parse_args()

    result = query_abuseipdb(args.ip, args.api_key)
    print(json.dumps(result, indent=4))
