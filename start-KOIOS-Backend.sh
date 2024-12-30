#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default credentials
ES_USERNAME=""
ES_PASSWORD=""

# Function to prompt for credentials
get_credentials() {
    if [ -z "$ES_USERNAME" ] || [ -z "$ES_PASSWORD" ]; then
        echo -e "${YELLOW}Elasticsearch authentication required${NC}"
        read -p "Enter Elasticsearch username: " ES_USERNAME
        read -s -p "Enter Elasticsearch password: " ES_PASSWORD
        echo # New line after password input
    fi
}

# Function to check container status and manage them
manage_containers() {
    echo -e "${BLUE}Checking existing containers...${NC}"
    
    # Get container IDs if they exist
    ES_CONTAINER=$(docker ps -aq -f name=elasticsearch)
    KIBANA_CONTAINER=$(docker ps -aq -f name=kibana)
    
    # Check Elasticsearch container
    if [ ! -z "$ES_CONTAINER" ]; then
        echo -e "Found Elasticsearch container: ${GREEN}$ES_CONTAINER${NC}"
        if [ "$(docker ps -q -f id=$ES_CONTAINER)" ]; then
            echo "Elasticsearch container is running"
        else
            echo "Starting existing Elasticsearch container..."
            docker start $ES_CONTAINER
        fi
    else
        echo -e "${RED}No Elasticsearch container found${NC}"
        exit 1
    fi

    # Check Kibana container
    if [ ! -z "$KIBANA_CONTAINER" ]; then
        echo -e "Found Kibana container: ${GREEN}$KIBANA_CONTAINER${NC}"
        if [ "$(docker ps -q -f id=$KIBANA_CONTAINER)" ]; then
            echo "Kibana container is running"
        else
            echo "Starting existing Kibana container..."
            docker start $KIBANA_CONTAINER
        fi
    else
        echo -e "${RED}No Kibana container found${NC}"
        exit 1
    fi
}

# Function to check Elasticsearch health
check_es_health() {
    local auth_header="Authorization: Basic $(echo -n "${ES_USERNAME}:${ES_PASSWORD}" | base64)"
    local health_response
    
    echo "Checking Elasticsearch health..."
    health_response=$(curl -s -k \
        -H "$auth_header" \
        --insecure \
        "https://localhost:9200/_cluster/health")
    
    echo -e "${GREEN}✓ Elasticsearch is running${NC}"
    echo "Health Status: $status"
    return 0
}

# Function to start services
start_services() {
    echo -e "${GREEN}Starting services...${NC}"
    get_credentials
    manage_containers

    # Wait for Elasticsearch to be healthy
    echo "Waiting for Elasticsearch to be ready..."
    local max_attempts=30
    local attempt=1
    while ! check_es_health >/dev/null 2>&1; do
        if [ $attempt -eq $max_attempts ]; then
            echo -e "${RED}Elasticsearch failed to become healthy after $(( max_attempts * 5 )) seconds${NC}"
            exit 1
        fi
        echo "Waiting... Attempt $attempt/$max_attempts"
        sleep 5
        ((attempt++))
    done

    echo -e "\n${GREEN}Services are running!${NC}"
    echo "Elasticsearch: https://localhost:9200"
    echo "Kibana: http://localhost:5601"
    
    # Display running containers
    echo -e "\n${YELLOW}Running Containers:${NC}"
    docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}" | grep -E 'elasticsearch|kibana'

    echo -e "\n${YELLOW}Starting n8n:${NC}"
    pm2 start n8n

    echo -e "\n${YELLOW}Checking n8n Status:${NC}"
    pm2 list
}

# Function to stop services
stop_services() {
    echo -e "${YELLOW}Stopping services...${NC}"
    
    # Get container IDs
    ES_CONTAINER=$(docker ps -aq -f name=elasticsearch)
    KIBANA_CONTAINER=$(docker ps -aq -f name=kibana)
    
    # Stop containers if they exist
    if [ ! -z "$ES_CONTAINER" ]; then
        echo "Stopping Elasticsearch container: $ES_CONTAINER"
        docker stop $ES_CONTAINER
    fi
    
    if [ ! -z "$KIBANA_CONTAINER" ]; then
        echo "Stopping Kibana container: $KIBANA_CONTAINER"
        docker stop $KIBANA_CONTAINER
    fi
    
    echo -e "${GREEN}Services stopped${NC}"

    echo -e "\n${YELLOW}Stopping n8n:${NC}"
    pm2 stop n8n

    echo -e "\n${YELLOW}Checking n8n Status:${NC}"
    pm2 list
}

# Function to check status
check_status() {
    echo -e "${YELLOW}Checking services status...${NC}"
    get_credentials
    
    # Display container status
    echo -e "\n${BLUE}Container Status:${NC}"
    docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E 'elasticsearch|kibana'
    
    # Check Elasticsearch health if it's running
    if [ "$(docker ps -q -f name=elasticsearch)" ]; then
        check_es_health
    fi

    # Check n8n if Running
    pm2 list
}

# Main script logic
case "$1" in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    status)
        check_status
        ;;
    *)
        echo "Usage: $0 {start|stop|status}"
        exit 1
        ;;
esac
