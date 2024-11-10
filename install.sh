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

    # Install dbus if not already installed
    if ! command_exists dbus-launch; then
        log_message "Installing dbus..."
        apt-get install -y dbus
    else
        log_message "dbus is already installed."
    fi

    # Install feh for setting wallpaper
    if ! command_exists feh; then
        log_message "Installing feh..."
        apt-get install -y feh
    else
        log_message "feh is already installed."
    fi

    # Install jq for JSON parsing
    if ! command_exists jq; then
        log_message "Installing jq..."
        apt-get install -y jq
    else
        log_message "jq is already installed."
    fi

    # Install git if not already installed
    if ! command_exists git; then
        log_message "Installing git..."
        apt-get install -y git
    else
        log_message "git is already installed."
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

# Function to install Portainer
install_portainer() {
    if docker ps -a --format '{{.Names}}' | grep -q "^portainer$"; then
        log_message "Portainer is already installed. Skipping installation."
        return
    fi

    log_message "Installing Portainer..."
    docker volume create portainer_data
    docker run -d -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce
    log_message "Portainer installation completed."
}

# Function to install Python
install_python() {
    if command_exists python3; then
        log_message "Python is already installed. Skipping installation."
        return
    fi

    log_message "Installing Python..."
    apt-get update
    apt-get install -y python3 python3-pip
    log_message "Python installation completed."
}

# Function to install Go
install_go() {
    if command_exists go; then
        log_message "Go is already installed. Skipping installation."
        return
    fi

    log_message "Installing Go..."
    local go_version="1.21.1"
    wget https://go.dev/dl/go${go_version}.linux-amd64.tar.gz
    rm -rf /usr/local/go
    tar -C /usr/local -xzf go${go_version}.linux-amd64.tar.gz
    rm go${go_version}.linux-amd64.tar.gz
    export PATH=$PATH:/usr/local/go/bin
    echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.profile
    source ~/.profile
    log_message "Go installation completed."
}

# Function to set up and start ELK stack using docker-elk repository
setup_elk() {
    local repo_url="https://github.com/deviantony/docker-elk"
    local repo_dir="docker-elk"

    if [ -d "$repo_dir" ]; then
        log_message "Repository $repo_dir already exists. Pulling latest changes..."
        cd "$repo_dir" && git pull
    else
        log_message "Cloning the repository from $repo_url..."
        git clone "$repo_url"
        cd "$repo_dir"
    fi

    log_message "Setting up the ELK stack..."
    docker compose up setup

    log_message "Starting the ELK stack..."
    docker compose up -d

    log_message "ELK stack setup and started successfully."

    # Test the ELK stack
    log_message "Testing ELK stack with curl..."
    if curl -u elastic:changeme http://localhost:9200; then
        log_message "ELK stack is running and accessible."
    else
        log_message "Failed to access ELK stack. Please check the logs for details."
    fi

    # Go back to the parent directory for wallpaper change
    cd ..
}

# Function to change wallpaper using feh
change_wallpaper() {
    local wallpaper_path="$(pwd)/wallpaper.png"

    if [ ! -f "$wallpaper_path" ]; then
        log_message "Wallpaper file not found at $wallpaper_path. Skipping wallpaper change."
        return
    fi

    log_message "Changing wallpaper using feh..."
    feh --bg-scale "$wallpaper_path"
    log_message "Wallpaper changed."
}

# Main script execution
check_root
install_dependencies
install_docker
install_portainer
install_python
install_go
setup_elk
change_wallpaper

log_message "All tasks completed successfully!"
