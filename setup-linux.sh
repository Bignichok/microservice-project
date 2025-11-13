#!/bin/bash

# Linux Setup Script for EKS + Terraform + Helm project
# Run this script to install all required tools

set -e

echo "🐧 Setting up tools for Linux..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Helper functions
log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   error "This script should not be run as root"
   exit 1
fi

# Update system
log "Updating system packages..."
sudo apt update

# Install basic tools
log "Installing basic tools..."
sudo apt install -y curl wget unzip jq git

# Install Terraform
log "Installing Terraform..."
if ! command -v terraform &> /dev/null; then
    wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update && sudo apt install terraform
    log "✓ Terraform installed"
else
    log "✓ Terraform already installed"
fi

# Install AWS CLI
log "Installing AWS CLI..."
if ! command -v aws &> /dev/null; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
    log "✓ AWS CLI installed"
else
    log "✓ AWS CLI already installed"
fi

# Install kubectl
log "Installing kubectl..."
if ! command -v kubectl &> /dev/null; then
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
    log "✓ kubectl installed"
else
    log "✓ kubectl already installed"
fi

# Install Helm
log "Installing Helm..."
if ! command -v helm &> /dev/null; then
    curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
    sudo apt update && sudo apt install helm
    log "✓ Helm installed"
else
    log "✓ Helm already installed"
fi

# Install Docker
log "Installing Docker..."
if ! command -v docker &> /dev/null; then
    sudo apt install -y docker.io docker-compose
    sudo usermod -aG docker $USER
    sudo systemctl enable docker
    sudo systemctl start docker
    log "✓ Docker installed"
    warn "⚠️  You need to logout and login again for Docker group to take effect"
else
    log "✓ Docker already installed"
fi

# Install Make
log "Installing Make..."
if ! command -v make &> /dev/null; then
    sudo apt install -y make
    log "✓ Make installed"
else
    log "✓ Make already installed"
fi

echo ""
log "🎉 All tools installed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Configure AWS: aws configure"
echo "2. Logout and login again (for Docker)"
echo "3. Run: make check-tools"
echo "4. Run: make check-aws"
echo ""