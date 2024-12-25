# KOIOS
My Collection of OSINT Scripts. 

Some are wrapped around other tools and other are implemented by me. At end its JSON output and stored somewhere 😁

------------------- 
`Project is Still being Developed and Will share the full architecture and usage`

## Architecture 

![Architecture](Docs/image.png)

## Tools Used
### OSINT / Information Gathering
|Tool|API|Comments|
|----|----|-------|
|Chaos| API Key Required| |
|AbuseIP DB |API Key Required| |
|IP Qualtiy Score |API Key Required| |
|Alien Vault OTX | API Key Required | |
|Virus Total | API Key Required | |

### Attack Surface Management
|Tool| API | Comment|
|----|----|-------|
| Sub Finder | | Built in Tool|
|Chaos |API Key Required | |

### Threat Hunting


## Containers Deployed
1) Portainer (Container Management)
2) Elastic 
3) Kibana
4) Active Pieces (Workflow Management)
5) N8N (Automation)


## Deployment
1) Clone this Repo on Ubuntu 22 or Ubuntu 24 VM. These were distro used for Testing 
```shell
git clone https://github.com/g33kroid/KOIOS
```
2) As Root run Prepare VM Script
```shell
sudo bash ./prepare-vm.sh
```
3) Update the Elastic Variables in `prepare-elk.sh` choose the Elastic Version to install and Put the Password for Elastic and Kibana SystemS
```bash
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
```
