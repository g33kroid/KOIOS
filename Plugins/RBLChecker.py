import argparse
import json
import dns.resolver
import logging

# Configure logging
logging.basicConfig(filename='rbl_check.log', level=logging.INFO, 
                    format='%(asctime)s - %(levelname)s - %(message)s')

def check_rbl(ip):
    rbl_servers = [
        'zen.spamhaus.org',
        'bl.spamcop.net',
        'dnsbl.sorbs.net',
        'b.barracudacentral.org',
        'cbl.abuseat.org',
        'dnsbl-1.uceprotect.net',
        'dnsbl-2.uceprotect.net',
        'dnsbl-3.uceprotect.net',
        'psbl.surriel.com',
        'dnsbl.sorbs.net',
        'bl.spamcop.net',
        'list.dsbl.org',
        'sbl.spamhaus.org',
        'xbl.spamhaus.org',
        'pbl.spamhaus.org',
        'dnsbl.dronebl.org',
        'db.wpbl.info',
        'ubl.unsubscore.com',
        'rbl.interserver.net'
    ]
    results = {}
    try:
        reversed_ip = '.'.join(reversed(ip.split('.')))
        for rbl in rbl_servers:
            query = f"{reversed_ip}.{rbl}"
            try:
                dns.resolver.resolve(query, 'A')
                results[rbl] = 'Listed'
            except dns.resolver.NXDOMAIN:
                results[rbl] = 'Not Listed'
            except Exception as e:
                logging.warning(f"Error checking RBL {rbl} for {ip}: {e}")
                results[rbl] = f'Error: {str(e)}'
    except Exception as e:
        logging.error(f"Error processing RBLs for {ip}: {e}")
        results['error'] = str(e)
    return results

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Check IP reputation against RBL (Real-time Blackhole List)")
    parser.add_argument("ip", help="IP address to check")
    args = parser.parse_args()

    result = check_rbl(args.ip)
    print(json.dumps(result, indent=4))
