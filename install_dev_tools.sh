#!/bin/bash

# Script for automatic installation of development tools
# Author: Mykyta Samoilenko

set -e  # Stop script on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/debian_version ]; then
            OS="debian"
            log_info "Detected Ubuntu/Debian system"
        elif [ -f /etc/redhat-release ]; then
            OS="redhat"
            log_info "Detected RedHat/CentOS system"
        else
            OS="linux"
            log_info "Detected Linux system"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        log_info "Detected macOS system"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
        OS="windows"
        log_info "Detected Windows system"
    else
        OS="unknown"
        log_warning "Unknown operating system: $OSTYPE"
    fi
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

install_docker() {
    log_info "Checking for Docker installation..."
    
    if command_exists docker; then
        DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
        log_success "Docker is already installed (version: $DOCKER_VERSION)"
        return 0
    fi
    
    log_info "Installing Docker..."
    
    case $OS in
        "debian")
            # Update packages
            sudo apt-get update
            
            # Install dependencies
            sudo apt-get install -y \
                ca-certificates \
                curl \
                gnupg \
                lsb-release
            
            # Add Docker GPG key
            sudo mkdir -m 0755 -p /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            
            # Add Docker repository
            echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
                $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            # Install Docker
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        "redhat")
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        "macos")
            if command_exists brew; then
                brew install --cask docker
            else
                log_error "Homebrew not found. Please install Docker Desktop manually from https://docker.com/products/docker-desktop"
                return 1
            fi
            ;;
        "windows")
            log_warning "For Windows, it's recommended to install Docker Desktop from https://docker.com/products/docker-desktop"
            log_warning "Or use WSL2 with a Linux distribution"
            return 1
            ;;
        *)
            log_error "Automatic Docker installation is not supported for this OS"
            return 1
            ;;
    esac
    
    # Add current user to docker group
    if [[ "$OS" == "debian" ]] || [[ "$OS" == "redhat" ]]; then
        sudo usermod -aG docker $USER
        log_warning "Please log out and back in or run 'newgrp docker' to activate the docker group"
    fi
    
    log_success "Docker installed successfully!"
}

install_docker_compose() {
    log_info "Checking for Docker Compose installation..."
    
    if command_exists docker-compose || docker compose version >/dev/null 2>&1; then
        if command_exists docker-compose; then
            COMPOSE_VERSION=$(docker-compose --version | cut -d' ' -f3 | cut -d',' -f1)
        else
            COMPOSE_VERSION=$(docker compose version --short)
        fi
        log_success "Docker Compose is already installed (version: $COMPOSE_VERSION)"
        return 0
    fi
    
    log_info "Installing Docker Compose..."
    
    case $OS in
        "debian"|"redhat")
            # Get the latest version
            COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
            
            # Download Docker Compose
            sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            
            # Make executable
            sudo chmod +x /usr/local/bin/docker-compose
            ;;
        "macos")
            if command_exists brew; then
                brew install docker-compose
            else
                log_error "Homebrew not found for Docker Compose installation"
                return 1
            fi
            ;;
        "windows")
            log_warning "Docker Compose is usually included with Docker Desktop for Windows"
            ;;
        *)
            log_error "Automatic Docker Compose installation is not supported for this OS"
            return 1
            ;;
    esac
    
    log_success "Docker Compose installed successfully!"
}

install_python() {
    log_info "Checking for Python installation..."
    
    if command_exists python3; then
        PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
        MAJOR_VERSION=$(echo $PYTHON_VERSION | cut -d'.' -f1)
        MINOR_VERSION=$(echo $PYTHON_VERSION | cut -d'.' -f2)
        
        if [[ $MAJOR_VERSION -eq 3 ]] && [[ $MINOR_VERSION -ge 14 ]]; then
            log_success "Python $PYTHON_VERSION is already installed and meets requirements (3.14+)"
            return 0
        else
            log_warning "Python $PYTHON_VERSION is installed, but version 3.14+ is required"
        fi
    elif command_exists python; then
        PYTHON_VERSION=$(python --version 2>&1 | cut -d' ' -f2)
        MAJOR_VERSION=$(echo $PYTHON_VERSION | cut -d'.' -f1)
        
        if [[ $MAJOR_VERSION -eq 3 ]]; then
            MINOR_VERSION=$(echo $PYTHON_VERSION | cut -d'.' -f2)
            if [[ $MINOR_VERSION -ge 14 ]]; then
                log_success "Python $PYTHON_VERSION is already installed and meets requirements (3.14+)"
                return 0
            else
                log_warning "Python $PYTHON_VERSION is installed, but version 3.14+ is required"
            fi
        else
            log_warning "Python 2.x is installed, but Python 3.14+ is required"
        fi
    fi
    
    log_info "Installing Python 3.14+..."
    
    case $OS in
        "debian")
            # Add PPA for newer Python versions
            sudo apt-get update
            sudo apt-get install -y software-properties-common
            sudo add-apt-repository -y ppa:deadsnakes/ppa
            sudo apt-get update
            
            # Try to install Python 3.14
            if apt-cache show python3.14 >/dev/null 2>&1; then
                sudo apt-get install -y python3.14 python3.14-pip python3.14-dev python3.14-venv
                sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.14 1
            else
                log_warning "Python 3.14 is not available in repositories. Installing latest available version..."
                sudo apt-get install -y python3 python3-pip python3-dev python3-venv
            fi
            ;;
        "redhat")
            # Install via dnf/yum
            if command_exists dnf; then
                sudo dnf install -y python3 python3-pip python3-devel
            else
                sudo yum install -y python3 python3-pip python3-devel
            fi
            ;;
        "macos")
            if command_exists brew; then
                # Try to install Python 3.14
                brew install python@3.14 2>/dev/null || brew install python@3.13 || brew install python@3.12
            else
                log_error "Homebrew not found for Python installation"
                return 1
            fi
            ;;
        "windows")
            log_warning "For Windows, it's recommended to download Python from https://python.org/downloads/"
            log_warning "Or use Microsoft Store"
            return 1
            ;;
        *)
            log_error "Automatic Python installation is not supported for this OS"
            return 1
            ;;
    esac
    
    log_success "Python installed successfully!"
}

install_django() {
    log_info "Checking for Django installation..."
    
    # Check if pip is available
    if ! command_exists pip3 && ! command_exists pip; then
        log_error "pip not found. Please install Python with pip first"
        return 1
    fi
    
    # Choose pip command
    PIP_CMD="pip3"
    if ! command_exists pip3; then
        PIP_CMD="pip"
    fi
    
    # Check Django installation
    if $PIP_CMD show django >/dev/null 2>&1; then
        DJANGO_VERSION=$($PIP_CMD show django | grep Version | cut -d' ' -f2)
        log_success "Django is already installed (version: $DJANGO_VERSION)"
        return 0
    fi
    
    log_info "Installing Django via pip..."
    
    # Update pip
    $PIP_CMD install --upgrade pip
    
    # Install Django
    $PIP_CMD install django
    
    log_success "Django installed successfully!"
}

verify_installation() {
    log_info "Checking installed tools..."
    
    echo "========================================"
    echo "           INSTALLATION RESULTS"
    echo "========================================"
    
    # Check Docker
    if command_exists docker; then
        DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
        echo -e "${GREEN}✓${NC} Docker: $DOCKER_VERSION"
    else
        echo -e "${RED}✗${NC} Docker: not installed"
    fi
    
    # Check Docker Compose
    if command_exists docker-compose; then
        COMPOSE_VERSION=$(docker-compose --version | cut -d' ' -f3 | cut -d',' -f1)
        echo -e "${GREEN}✓${NC} Docker Compose: $COMPOSE_VERSION"
    elif docker compose version >/dev/null 2>&1; then
        COMPOSE_VERSION=$(docker compose version --short)
        echo -e "${GREEN}✓${NC} Docker Compose: $COMPOSE_VERSION"
    else
        echo -e "${RED}✗${NC} Docker Compose: not installed"
    fi
    
    # Check Python
    if command_exists python3; then
        PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
        echo -e "${GREEN}✓${NC} Python: $PYTHON_VERSION"
    elif command_exists python; then
        PYTHON_VERSION=$(python --version 2>&1 | cut -d' ' -f2)
        echo -e "${GREEN}✓${NC} Python: $PYTHON_VERSION"
    else
        echo -e "${RED}✗${NC} Python: not installed"
    fi
    
    # Check Django
    PIP_CMD="pip3"
    if ! command_exists pip3; then
        PIP_CMD="pip"
    fi
    
    if command_exists $PIP_CMD && $PIP_CMD show django >/dev/null 2>&1; then
        DJANGO_VERSION=$($PIP_CMD show django | grep Version | cut -d' ' -f2)
        echo -e "${GREEN}✓${NC} Django: $DJANGO_VERSION"
    else
        echo -e "${RED}✗${NC} Django: not installed"
    fi
    
    echo "========================================"
}

main() {
    log_info "Starting development tools installation..."
    log_info "Date: $(date)"
    
    detect_os
    
    install_docker
    install_docker_compose
    install_python
    install_django
    
    verify_installation
    
    log_success "Installation completed!"
    
    echo ""
    log_info "Additional steps:"
    echo "1. Log out and back in or run 'newgrp docker' to activate the docker group"
    echo "2. Test Docker: docker run hello-world"
    echo "3. Create a new Django project: django-admin startproject myproject"
}

main "$@"