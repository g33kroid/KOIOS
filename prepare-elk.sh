#!/bin/bash

# Set variables
ELASTIC_VERSION="8.10.2"
DOCKER_NETWORK="elastic-network"
ELASTIC_CONTAINER_NAME="elasticsearch"
KIBANA_CONTAINER_NAME="kibana"
CERTS_DIR=$(pwd)/certs
ELASTIC_PORT=9200
KIBANA_PORT=5601
ELASTIC_PASSWORD="Hunter1234"  # Password for the elastic user
KIBANA_SYSTEM_PASSWORD="Hunter1234"  # Password for the kibana_system user

echo "Starting deployment of Elasticsearch and Kibana with SSL..."

# Create a Docker network
docker network create $DOCKER_NETWORK || echo "Network $DOCKER_NETWORK already exists"

# Create the certs directory and set correct permissions
echo "Creating certs directory..."
mkdir -p $CERTS_DIR
chmod 777 $CERTS_DIR

# Generate SSL certificates for Elasticsearch
echo "Generating SSL certificates for Elasticsearch..."
docker run --rm \
  --user root \
  --name elastic-certutil \
  --network $DOCKER_NETWORK \
  -v $CERTS_DIR:/usr/share/elasticsearch/config/certs \
  docker.elastic.co/elasticsearch/elasticsearch:$ELASTIC_VERSION \
  /bin/bash -c " \
    elasticsearch-certutil ca --silent --pem -out /usr/share/elasticsearch/config/certs/elastic-stack-ca.zip && \
    unzip /usr/share/elasticsearch/config/certs/elastic-stack-ca.zip -d /usr/share/elasticsearch/config/certs && \
    elasticsearch-certutil cert --silent --pem --ca-cert /usr/share/elasticsearch/config/certs/ca/ca.crt --ca-key /usr/share/elasticsearch/config/certs/ca/ca.key -out /usr/share/elasticsearch/config/certs/elastic-certificates.zip && \
    unzip /usr/share/elasticsearch/config/certs/elastic-certificates.zip -d /usr/share/elasticsearch/config/certs"

# Deploy Elasticsearch with SSL
echo "Deploying Elasticsearch container: $ELASTIC_CONTAINER_NAME"
docker run -d \
  --name $ELASTIC_CONTAINER_NAME \
  --network $DOCKER_NETWORK \
  -p $ELASTIC_PORT:9200 \
  -v $CERTS_DIR:/usr/share/elasticsearch/config/certs \
  -e "discovery.type=single-node" \
  -e "xpack.security.enabled=true" \
  -e "xpack.security.http.ssl.enabled=true" \
  -e "xpack.security.http.ssl.key=/usr/share/elasticsearch/config/certs/instance/instance.key" \
  -e "xpack.security.http.ssl.certificate=/usr/share/elasticsearch/config/certs/instance/instance.crt" \
  -e "xpack.security.http.ssl.certificate_authorities=/usr/share/elasticsearch/config/certs/ca/ca.crt" \
  -e "ELASTIC_PASSWORD=$ELASTIC_PASSWORD" \
  docker.elastic.co/elasticsearch/elasticsearch:$ELASTIC_VERSION

# Wait for Elasticsearch to start
echo "Waiting for Elasticsearch to start..."
sleep 60

# Set the kibana_system password
echo "Setting the kibana_system password..."
docker exec -it $ELASTIC_CONTAINER_NAME \
  curl -X POST -k -u elastic:$ELASTIC_PASSWORD "https://localhost:9200/_security/user/kibana_system/_password" \
  -H "Content-Type: application/json" \
  -d "{\"password\": \"$KIBANA_SYSTEM_PASSWORD\"}"

# Deploy Kibana with SSL
echo "Deploying Kibana container: $KIBANA_CONTAINER_NAME"
docker run -d \
  --name $KIBANA_CONTAINER_NAME \
  --network $DOCKER_NETWORK \
  -p $KIBANA_PORT:5601 \
  -e "ELASTICSEARCH_HOSTS=https://$ELASTIC_CONTAINER_NAME:9200" \
  -e "ELASTICSEARCH_USERNAME=kibana_system" \
  -e "ELASTICSEARCH_PASSWORD=$KIBANA_SYSTEM_PASSWORD" \
  -e "ELASTICSEARCH_SSL_CERTIFICATEAUTHORITIES=/usr/share/elasticsearch/config/certs/ca/ca.crt" \
  -v $CERTS_DIR:/usr/share/elasticsearch/config/certs \
  docker.elastic.co/kibana/kibana:$ELASTIC_VERSION

echo "Deployment complete. Access Elasticsearch at https://localhost:$ELASTIC_PORT and Kibana at http://localhost:$KIBANA_PORT"