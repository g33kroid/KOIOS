import argparse
import json
import requests
import logging

# Configure logging
logging.basicConfig(filename='ipqualityscore.log', level=logging.INFO, 
                    format='%(asctime)s - %(levelname)s - %(message)s')

def query_ipqualityscore(ip, api_key):
    url = f'https://ipqualityscore.com/api/json/ip/{api_key}/{ip}'
    try:
        response = requests.get(url)
        response.raise_for_status()
        return response.json()
    except requests.RequestException as e:
        logging.error(f"Failed to query IPQualityScore for {ip}: {e}")
        return {"error": f"Failed to query IPQualityScore for {ip}"}

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Query IP reputation from IPQualityScore")
    parser.add_argument("ip", help="IP address to check")
    parser.add_argument("api_key", help="IPQualityScore API key")
    args = parser.parse_args()

    result = query_ipqualityscore(args.ip, args.api_key)
    print(json.dumps(result, indent=4))
