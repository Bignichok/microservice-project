#!/bin/bash

# Enhanced deploy script with RDS support
# Usage: ./deploy-rds.sh [--aurora|--mysql] [--destroy]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
RDS_TYPE="aurora"
DESTROY=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --aurora)
            RDS_TYPE="aurora"
            shift
            ;;
        --mysql)
            RDS_TYPE="mysql"
            shift
            ;;
        --destroy)
            DESTROY=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--aurora|--mysql] [--destroy]"
            echo ""
            echo "Options:"
            echo "  --aurora    Deploy Aurora PostgreSQL (default)"
            echo "  --mysql     Deploy regular MySQL RDS"
            echo "  --destroy   Destroy RDS infrastructure"
            echo "  -h, --help  Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option $1"
            exit 1
            ;;
    esac
done

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

check_prerequisites() {
    print_header "Checking Prerequisites"
    
    local missing_tools=()
    
    if ! command -v terraform &> /dev/null; then
        missing_tools+=("terraform")
    fi
    
    if ! command -v aws &> /dev/null; then
        missing_tools+=("aws-cli")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured"
        exit 1
    fi
    
    print_success "All prerequisites met"
}

setup_terraform_vars() {
    print_header "Setting up Terraform Variables"
    
    if [ ! -f "$SCRIPT_DIR/terraform.tfvars" ]; then
        print_warning "terraform.tfvars not found, creating from example"
        
        if [ "$RDS_TYPE" == "aurora" ]; then
            cat > "$SCRIPT_DIR/terraform.tfvars" << EOF
aws_region = "us-west-2"
db_password = "$(openssl rand -base64 32 | tr -d '\n')"
EOF
        else
            cat > "$SCRIPT_DIR/terraform.tfvars" << EOF
aws_region = "us-west-2"
db_password = "$(openssl rand -base64 32 | tr -d '\n')"
EOF
        fi
        
        print_success "Created terraform.tfvars with random password"
        print_warning "Please review and update terraform.tfvars if needed"
    else
        print_success "Using existing terraform.tfvars"
    fi
}

deploy_rds() {
    print_header "Deploying RDS ($RDS_TYPE)"
    
    cd "$SCRIPT_DIR"
    
    # Initialize Terraform
    print_header "Initializing Terraform"
    terraform init
    
    # Plan deployment
    print_header "Planning RDS Deployment"
    terraform plan -target=module.database
    
    # Apply deployment
    print_header "Applying RDS Deployment"
    terraform apply -target=module.database -auto-approve
    
    print_success "RDS deployment completed successfully"
    
    # Show connection info
    print_header "Database Connection Information"
    terraform output -json | jq -r '.database_connection_info.value | to_entries[] | "\(.key): \(.value)"' || true
}

destroy_rds() {
    print_header "Destroying RDS Infrastructure"
    
    cd "$SCRIPT_DIR"
    
    print_warning "This will permanently destroy the database and all data!"
    read -p "Are you sure? (type 'yes' to confirm): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_error "Destruction cancelled"
        exit 1
    fi
    
    terraform destroy -target=module.database -auto-approve
    print_success "RDS infrastructure destroyed"
}

main() {
    if [ "$DESTROY" = true ]; then
        check_prerequisites
        destroy_rds
    else
        check_prerequisites
        setup_terraform_vars
        deploy_rds
    fi
}

# Run main function
main "$@"