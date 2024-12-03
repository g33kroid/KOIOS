import argparse
import json
import requests
import logging

# Configure logging
logging.basicConfig(filename='alienvault.log', level=logging.INFO, 
                    format='%(asctime)s - %(levelname)s - %(message)s')

def query_alienvault(ip, api_key):
    url = f'https://otx.alienvault.com/api/v1/indicators/IPv4/{ip}/reputation'
    headers = {
        'X-OTX-API-KEY': api_key
    }
    try:
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        return response.json()
    except requests.RequestException as e:
        logging.error(f"Failed to query AlienVault for {ip}: {e}")
        return {"error": f"Failed to query AlienVault for {ip}"}

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Query IP reputation from AlienVault")
    parser.add_argument("ip", help="IP address to check")
    parser.add_argument("api_key", help="AlienVault API key")
    args = parser.parse_args()

    result = query_alienvault(args.ip, args.api_key)
    print(json.dumps(result, indent=4))
