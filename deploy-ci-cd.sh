#!/bin/bash

# Comprehensive CI/CD Infrastructure Deployment Script
# This script deploys the complete infrastructure including EKS, Jenkins, and Argo CD

set -e

# Configuration
AWS_REGION="${AWS_REGION:-us-west-2}"
CLUSTER_NAME="microservice-project-eks-cluster"
TERRAFORM_STATE_BUCKET="terraform-state-bucket-microservice-project-bignichok"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    local missing_tools=()
    
    if ! command -v terraform &> /dev/null; then
        missing_tools+=("terraform")
    fi
    
    if ! command -v aws &> /dev/null; then
        missing_tools+=("aws-cli")
    fi
    
    if ! command -v kubectl &> /dev/null; then
        missing_tools+=("kubectl")
    fi
    
    if ! command -v helm &> /dev/null; then
        missing_tools+=("helm")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        echo "Please install the missing tools and try again."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured or invalid"
        echo "Please run 'aws configure' to set up your credentials."
        exit 1
    fi
    
    print_success "All prerequisites met!"
}

# Function to initialize and deploy infrastructure
deploy_infrastructure() {
    print_status "Deploying infrastructure with Terraform..."
    
    # Initialize Terraform
    print_status "Initializing Terraform..."
    terraform init
    
    # Validate configuration
    print_status "Validating Terraform configuration..."
    terraform validate
    
    # Plan deployment
    print_status "Planning Terraform deployment..."
    terraform plan -out=tfplan
    
    # Apply deployment
    print_status "Applying Terraform configuration..."
    terraform apply tfplan
    
    # Clean up plan file
    rm -f tfplan
    
    print_success "Infrastructure deployed successfully!"
}

# Function to configure kubectl
configure_kubectl() {
    print_status "Configuring kubectl for EKS cluster..."
    
    # Update kubeconfig
    aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME
    
    # Verify connection
    if kubectl cluster-info &> /dev/null; then
        print_success "kubectl configured successfully!"
    else
        print_error "Failed to configure kubectl"
        exit 1
    fi
    
    # Wait for cluster to be ready
    print_status "Waiting for cluster to be ready..."
    kubectl wait --for=condition=Ready nodes --all --timeout=600s
}

# Function to setup Jenkins
setup_jenkins() {
    print_status "Setting up Jenkins..."
    
    # Wait for Jenkins namespace
    print_status "Waiting for Jenkins namespace..."
    kubectl wait --for=condition=Ready namespace/jenkins --timeout=300s || true
    
    # Wait for Jenkins deployment
    print_status "Waiting for Jenkins to be ready..."
    kubectl wait --for=condition=Available deployment/jenkins -n jenkins --timeout=600s
    
    # Setup Jenkins credentials and configuration
    if [ -f "./setup-jenkins.sh" ]; then
        chmod +x ./setup-jenkins.sh
        
        # Get ECR repository URL from Terraform output
        ECR_URL=$(terraform output -raw ecr_info | grep -o '"repository_url": "[^"]*"' | cut -d'"' -f4)
        export ECR_REPOSITORY_URL=$ECR_URL
        
        ./setup-jenkins.sh
    else
        print_warning "setup-jenkins.sh script not found, skipping automated Jenkins setup"
    fi
    
    print_success "Jenkins setup completed!"
}

# Function to verify Argo CD
verify_argocd() {
    print_status "Verifying Argo CD installation..."
    
    # Wait for Argo CD namespace
    print_status "Waiting for ArgoCD namespace..."
    kubectl wait --for=condition=Ready namespace/argocd --timeout=300s || true
    
    # Wait for Argo CD server
    print_status "Waiting for ArgoCD server to be ready..."
    kubectl wait --for=condition=Available deployment/argocd-server -n argocd --timeout=600s
    
    print_success "Argo CD is ready!"
}

# Function to display access information
display_access_info() {
    print_success "Deployment completed successfully!"
    echo ""
    echo "========================================================================================"
    echo "                                ACCESS INFORMATION"
    echo "========================================================================================"
    
    # Jenkins information
    echo ""
    echo "🔧 JENKINS"
    echo "----------------------------------------------------------------------------------------"
    JENKINS_URL=$(kubectl get svc jenkins -n jenkins -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "Pending...")
    echo "URL: http://$JENKINS_URL"
    echo "Username: admin"
    echo "Password: admin123!"
    echo ""
    
    # Argo CD information
    echo "🚀 ARGO CD"
    echo "----------------------------------------------------------------------------------------"
    ARGOCD_URL=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "Pending...")
    echo "URL: http://$ARGOCD_URL"
    echo "Username: admin"
    echo "Password: admin123!"
    echo ""
    
    # ECR information
    echo "🐳 AMAZON ECR"
    echo "----------------------------------------------------------------------------------------"
    ECR_INFO=$(terraform output -json ecr_info 2>/dev/null || echo '{"repository_url": "Not available"}')
    ECR_URL=$(echo $ECR_INFO | grep -o '"repository_url": "[^"]*"' | cut -d'"' -f4)
    echo "Repository URL: $ECR_URL"
    echo ""
    
    # EKS information
    echo "☸️  EKS CLUSTER"
    echo "----------------------------------------------------------------------------------------"
    echo "Cluster Name: $CLUSTER_NAME"
    echo "Region: $AWS_REGION"
    echo ""
    
    echo "========================================================================================"
    echo "                                  NEXT STEPS"
    echo "========================================================================================"
    echo ""
    echo "1. 📚 Read the detailed guide: CI_CD_GUIDE.md"
    echo "2. 🔐 Configure GitHub credentials in Jenkins UI"
    echo "3. 🏗️  Create a Pipeline job in Jenkins pointing to your repository"
    echo "4. 🔄 Push code to trigger the CI/CD pipeline"
    echo "5. 👀 Monitor deployments in Argo CD UI"
    echo ""
    echo "For troubleshooting, check the CI_CD_GUIDE.md file."
    echo ""
}

# Function to display help
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Deploy complete CI/CD infrastructure with Jenkins, Argo CD, and EKS"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -d, --destroy  Destroy the infrastructure"
    echo "  -s, --skip-k8s Skip Kubernetes setup (Jenkins and Argo CD)"
    echo ""
    echo "Environment Variables:"
    echo "  AWS_REGION     AWS region (default: us-west-2)"
    echo ""
}

# Function to destroy infrastructure
destroy_infrastructure() {
    print_warning "This will destroy all infrastructure resources!"
    read -p "Are you sure? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        print_status "Destroying infrastructure..."
        terraform destroy -auto-approve
        print_success "Infrastructure destroyed!"
    else
        print_status "Destruction cancelled."
    fi
}

# Main function
main() {
    local skip_k8s=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--destroy)
                destroy_infrastructure
                exit 0
                ;;
            -s|--skip-k8s)
                skip_k8s=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Main deployment flow
    echo "🚀 Starting CI/CD Infrastructure Deployment"
    echo "==========================================="
    
    check_prerequisites
    deploy_infrastructure
    
    if [ "$skip_k8s" = false ]; then
        configure_kubectl
        setup_jenkins
        verify_argocd
    fi
    
    display_access_info
}

# Error handling
trap 'print_error "Script failed on line $LINENO"' ERR

# Run main function with all arguments
main "$@"