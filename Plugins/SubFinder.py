import subprocess
import json
import logging
import argparse
from datetime import datetime
from pathlib import Path

def setup_logging(log_level):
    """Configure logging with the specified level"""
    logging_levels = {
        'DEBUG': logging.DEBUG,
        'INFO': logging.INFO,
        'WARNING': logging.WARNING,
        'ERROR': logging.ERROR,
        'CRITICAL': logging.CRITICAL
    }
    
    # Configure logging format
    log_format = '%(asctime)s - %(levelname)s - %(message)s'
    logging.basicConfig(
        level=logging_levels.get(log_level.upper(), logging.INFO),
        format=log_format,
        handlers=[
            logging.StreamHandler(),  # Output to console
            logging.FileHandler('subfinder_script.log')  # Output to file
        ]
    )

def parse_arguments():
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(
        description='Run subfinder and process its output into JSON format',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    
    parser.add_argument(
        '-d', '--domain',
        required=True,
        help='Target domain to scan'
    )
    
    parser.add_argument(
        '-o', '--output',
        help='Output directory for JSON results',
        default='../results'
    )
    
    parser.add_argument(
        '--subfinder-path',
        help='Path to subfinder executable',
        default='/root/go/bin/subfinder'
    )
    
    parser.add_argument(
        '--log-level',
        choices=['DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL'],
        default='INFO',
        help='Set the logging level'
    )
    
    parser.add_argument(
        '--append',
        action='store_true',
        help='Append results to existing JSON file instead of creating new one'
    )
    
    return parser.parse_args()

def run_subfinder(domain, subfinder_path):
    """Execute subfinder command and return its output"""
    command = [subfinder_path, '-d', domain, '-oJ', '-all', '-cs']
    logging.debug(f"Executing command: {' '.join(command)}")
    
    try:
        process = subprocess.Popen(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        stdout, stderr = process.communicate()
        
        if stderr:
            stderr_output = stderr.decode('utf-8')
            if '[INF]' in stderr_output:  # subfinder prints status messages to stderr
                logging.info(stderr_output)
            else:
                logging.error(f"Stderr output: {stderr_output}")
        
        return stdout.decode('utf-8')
    
    except subprocess.CalledProcessError as e:
        logging.error(f"Failed to execute subfinder: {e}")
        raise
    except Exception as e:
        logging.error(f"An unexpected error occurred: {e}")
        raise

def process_subfinder_output(output, domain):
    """Process subfinder output and return structured data"""
    results = []
    for line in output.split('\n'):
        if line.strip() and line.strip().startswith('{'):
            try:
                json_data = json.loads(line)
                results.append(json_data)
            except json.JSONDecodeError as e:
                logging.warning(f"Failed to parse JSON line: {line}. Error: {e}")
                continue
    
    return {
        "scan_date": datetime.now().isoformat(),
        "target_domain": domain,
        "subdomains": results,
        "total_subdomains": len(results)
    }

def save_results(data, output_dir, domain, append=False):
    """Save or append results to JSON file"""
    # Create output directory if it doesn't exist
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)
    
    filename = output_path / f"subfinder_results_{domain}.json"
    
    if append and filename.exists():
        try:
            with open(filename, 'r') as f:
                existing_data = json.load(f)
            
            if not isinstance(existing_data, list):
                existing_data = [existing_data]
            existing_data.append(data)
            data = existing_data
            
            logging.info(f"Appending results to existing file: {filename}")
        except json.JSONDecodeError:
            logging.warning("Existing file is not valid JSON. Creating new file.")
    
    with open(filename, 'w') as f:
        json.dump(data, f, indent=4)
    
    logging.info(f"Results saved to: {filename}")
    return filename

def main():
    """Main function to orchestrate the subfinder execution and processing"""
    args = parse_arguments()
    setup_logging(args.log_level)
    
    logging.info(f"Starting subfinder scan for domain: {args.domain}")
    
    try:
        # Run subfinder
        output = run_subfinder(args.domain, args.subfinder_path)
        
        # Process results
        results = process_subfinder_output(output, args.domain)
        logging.info(f"Found {results['total_subdomains']} subdomains")
        
        # Save results
        output_file = save_results(
            results,
            args.output,
            args.domain,
            args.append
        )
        
        logging.info("Scan completed successfully")
        
    except Exception as e:
        logging.error(f"Script failed: {e}")
        raise

if __name__ == "__main__":
    main()
