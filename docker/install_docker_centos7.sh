#!/bin/bash
#
# This script is used to install the latest version of Docker on CentOS 7.

set -eu

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

DOCKER_REPO_URL="https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo"

if command -v docker &> /dev/null; then
  log "Docker is already installed. Skipping installation."
  docker --version
  exit 0
fi

log "Installing dependencies..."
yum install -y yum-utils

log "Setting up Docker repository..."
yum-config-manager --add-repo "$DOCKER_REPO_URL"
yum makecache fast

log "Installing Docker CE and dependencies..."
yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

log "Starting and enabling Docker service..."
systemctl enable docker --now

log "Verifying Docker installation..."
if docker info &> /dev/null; then
  log "Docker installed and running successfully."
else
  log "Docker installation failed."
  exit 1
fi
