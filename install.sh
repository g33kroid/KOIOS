#!/bin/bash

LOG_FILE="installation_log.txt"

# Function to check if the script is running as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "This script must be run as root" >&2
        exit 1
    fi
}

# Function to log messages with timestamps
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install dependencies
install_dependencies() {
    log_message "Installing necessary dependencies..."

    # Update package list
    apt-get update

    # Install dbus
    if ! command_exists dbus-launch; then
        log_message "Installing dbus..."
        apt-get install -y dbus
    else
        log_message "dbus is already installed."
    fi

    # Install feh
    if ! command_exists feh; then
        log_message "Installing feh..."
        apt-get install -y feh
    else
        log_message "feh is already installed."
    fi

    # Install jq
    if ! command_exists jq; then
        log_message "Installing jq..."
        apt-get install -y jq
    else
        log_message "jq is already installed."
    fi

    # Install git
    if ! command_exists git; then
        log_message "Installing git..."
        apt-get install -y git
    else
        log_message "git is already installed."
    fi

    # Install libpcap-dev for Naabu
    if ! dpkg -s libpcap-dev >/dev/null 2>&1; then
        log_message "Installing libpcap-dev..."
        apt-get install -y libpcap-dev
    else
        log_message "libpcap-dev is already installed."
    fi

    log_message "Dependencies installation completed."
}

# Function to install Docker
install_docker() {
    if command_exists docker; then
        log_message "Docker is already installed. Skipping installation."
        return
    fi

    log_message "Installing Docker..."
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
        apt-get remove -y $pkg
    done

    apt-get update
    apt-get install -y ca-certificates curl
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update

    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    systemctl start docker
    systemctl enable docker
    log_message "Docker installation completed."
}

# Function to install GoLang
install_go() {
    if command_exists go; then
        log_message "Go is already installed. Skipping installation."
        return
    fi

    log_message "Installing GoLang..."
    local go_version="1.23.3"
    wget https://go.dev/dl/go${go_version}.linux-amd64.tar.gz -O /tmp/go${go_version}.linux-amd64.tar.gz
    rm -rf /usr/local/go
    tar -C /usr/local -xzf /tmp/go${go_version}.linux-amd64.tar.gz
    rm /tmp/go${go_version}.linux-amd64.tar.gz
    export PATH=$PATH:/usr/local/go/bin
    echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.profile
    source ~/.profile
    log_message "GoLang installation completed."
}

# Function to install Project Discovery Tools
install_project_discovery_tools() {
    log_message "Installing Project Discovery Tools..."

    # Chaos
    log_message "Installing Chaos..."
    go install -v github.com/projectdiscovery/chaos-client/cmd/chaos@latest

    # Nuclei
    log_message "Installing Nuclei..."
    go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest

    # Subfinder
    log_message "Installing Subfinder..."
    go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest

    # Naabu
    log_message "Installing Naabu..."
    go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest

    # shuffledns
    log_message "Installing shuffledns..."
    go install -v github.com/projectdiscovery/shuffledns/cmd/shuffledns@latest

    log_message "Project Discovery Tools installation completed."
}

# Function to install Node.js and NPM
install_nodejs() {
    if command_exists node; then
        log_message "Node.js is already installed. Skipping installation."
        return
    fi

    log_message "Installing Node.js..."
    wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    source ~/.nvm/nvm.sh
    nvm install --lts
    log_message "Node.js installation completed."

    log_message "Installing NPM..."
    apt install -y npm
    log_message "NPM installation completed."
}

# Function to install PM2 and n8n
install_pm2_n8n() {
    log_message "Installing PM2 and n8n..."
    npm install -g pm2 n8n
    log_message "PM2 and n8n installation completed."
}

# Main script execution
check_root
install_dependencies
install_docker
install_go
install_project_discovery_tools
install_nodejs
install_pm2_n8n

log_message "All tasks completed successfully!"
