import argparse
import json
import requests
import logging

# Configure logging
logging.basicConfig(filename='ipinfo.log', level=logging.INFO, 
                    format='%(asctime)s - %(levelname)s - %(message)s')

def query_geolocation(ip):
    url = f'https://ipinfo.io/{ip}/json'
    try:
        response = requests.get(url)
        response.raise_for_status()
        return response.json()
    except requests.RequestException as e:
        logging.error(f"Failed to retrieve geolocation for {ip}: {e}")
        return {"error": f"Failed to retrieve geolocation for {ip}"}

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Retrieve geolocation data for an IP address using IPInfo")
    parser.add_argument("ip", help="IP address to check")
    args = parser.parse_args()

    result = query_geolocation(args.ip)
    print(json.dumps(result, indent=4))
