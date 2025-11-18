#!/bin/bash

# Comprehensive CI/CD Infrastructure Deployment Script
# This script deploys the complete infrastructure including EKS, Jenkins, and Argo CD

set -e

# Configuration
AWS_REGION="${AWS_REGION:-us-west-2}"
CLUSTER_NAME="microservice-project-eks-cluster"
TERRAFORM_STATE_BUCKET="terraform-state-bucket-microservice-project-bignichok"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

deploy_infrastructure() {
    print_status "Deploying infrastructure with Terraform..."
    
    print_status "Initializing Terraform..."
    terraform init
    
    print_status "Validating Terraform configuration..."
    terraform validate
    
    print_status "Planning Terraform deployment..."
    terraform plan -out=tfplan
    
    print_status "Applying Terraform configuration..."
    terraform apply tfplan
    
    # Clean up plan file
    rm -f tfplan
    
    print_success "Infrastructure deployed successfully!"
}

deploy_cicd() {
    print_status "Deploying CI/CD components (Jenkins and Argo CD)..."
    
    # Get cluster name and ECR URL from terraform outputs
    if ! terraform output eks_info > /dev/null 2>&1; then
        print_error "Cannot get infrastructure outputs. Please ensure infrastructure is deployed first."
        exit 1
    fi
    
    # Try to parse with jq first, then fallback to grep/cut
    if command -v jq &> /dev/null; then
        CLUSTER_NAME=$(terraform output -json eks_info | jq -r '.cluster_name')
        ECR_URL=$(terraform output -json ecr_info | jq -r '.repository_url')
    else
        print_warning "jq not found, using fallback parsing..."
        CLUSTER_NAME=$(terraform output -json eks_info | grep -o '"cluster_name":"[^"]*"' | cut -d'"' -f4)
        ECR_URL=$(terraform output -json ecr_info | grep -o '"repository_url":"[^"]*"' | cut -d'"' -f4)
    fi
    
    if [ -z "$CLUSTER_NAME" ] || [ -z "$ECR_URL" ]; then
        print_error "Failed to get cluster name or ECR URL from terraform outputs"
        print_status "Trying alternative output parsing..."
        
        # Alternative parsing with JSON output
        if command -v jq &> /dev/null; then
            CLUSTER_NAME=$(terraform output -json eks_info | jq -r '.cluster_name' 2>/dev/null || echo "")
            ECR_URL=$(terraform output -json ecr_info | jq -r '.repository_url' 2>/dev/null || echo "")
        else
            # Fallback without jq
            CLUSTER_NAME=$(terraform output -json eks_info | sed -n 's/.*"cluster_name":\s*"\([^"]*\)".*/\1/p')
            ECR_URL=$(terraform output -json ecr_info | sed -n 's/.*"repository_url":\s*"\([^"]*\)".*/\1/p')
        fi
        
        if [ -z "$CLUSTER_NAME" ] || [ -z "$ECR_URL" ]; then
            print_error "Still unable to parse terraform outputs"
            exit 1
        fi
    fi
    
    print_status "Using cluster: $CLUSTER_NAME"
    print_status "Using ECR URL: $ECR_URL"
    
    # Create terraform variables file in cicd directory
    cat > cicd/terraform.tfvars << EOF
cluster_name = "$CLUSTER_NAME"
ecr_repository_url = "$ECR_URL"
aws_region = "us-west-2"
EOF

    cd cicd
    
    print_status "Initializing CI/CD Terraform..."
    terraform init
    
    print_status "Planning CI/CD deployment..."
    terraform plan \
        -var-file="terraform.tfvars" \
        -out=cicd-plan

    print_status "Applying CI/CD configuration..."
    terraform apply cicd-plan

    rm -f cicd-plan
    cd ..    print_success "CI/CD components deployed successfully!"
}

configure_kubectl() {
    print_status "Configuring kubectl for EKS cluster..."
    
    aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME
    
    if kubectl cluster-info &> /dev/null; then
        print_success "kubectl configured successfully!"
    else
        print_error "Failed to configure kubectl"
        exit 1
    fi
    
    print_status "Waiting for cluster to be ready..."
    kubectl wait --for=condition=Ready nodes --all --timeout=600s
}

setup_jenkins() {
    print_status "Setting up Jenkins..."
    
    print_status "Waiting for Jenkins namespace..."
    kubectl wait --for=condition=Ready namespace/jenkins --timeout=300s || true
    
    print_status "Waiting for Jenkins to be ready..."
    kubectl wait --for=condition=Available deployment/jenkins -n jenkins --timeout=600s
    
    if [ -f "./setup-jenkins.sh" ]; then
        chmod +x ./setup-jenkins.sh
        
        ECR_URL=$(terraform output -raw ecr_info | grep -o '"repository_url": "[^"]*"' | cut -d'"' -f4)
        export ECR_REPOSITORY_URL=$ECR_URL
        
        ./setup-jenkins.sh
    else
        print_warning "setup-jenkins.sh script not found, skipping automated Jenkins setup"
    fi
    
    print_success "Jenkins setup completed!"
}

verify_argocd() {
    print_status "Verifying Argo CD installation..."
    
    print_status "Waiting for ArgoCD namespace..."
    kubectl wait --for=condition=Ready namespace/argocd --timeout=300s || true
    
    print_status "Waiting for ArgoCD server to be ready..."
    kubectl wait --for=condition=Available deployment/argocd-server -n argocd --timeout=600s
    
    print_success "Argo CD is ready!"
}

display_access_info() {
    print_success "Deployment completed successfully!"
    echo ""
    echo "========================================================================================"
    echo "                                ACCESS INFORMATION"
    echo "========================================================================================"
    
    echo ""
    echo "🔧 JENKINS"
    echo "----------------------------------------------------------------------------------------"
    JENKINS_URL=$(kubectl get svc jenkins -n jenkins -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "Pending...")
    echo "URL: http://$JENKINS_URL"
    echo "Username: admin"
    echo "Password: admin123!"
    echo ""
    
    echo "🚀 ARGO CD"
    echo "----------------------------------------------------------------------------------------"
    ARGOCD_URL=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "Pending...")
    echo "URL: http://$ARGOCD_URL"
    echo "Username: admin"
    echo "Password: admin123!"
    echo ""
    
    echo "🐳 AMAZON ECR"
    echo "----------------------------------------------------------------------------------------"
    ECR_INFO=$(terraform output -json ecr_info 2>/dev/null || echo '{"repository_url": "Not available"}')
    ECR_URL=$(echo $ECR_INFO | grep -o '"repository_url": "[^"]*"' | cut -d'"' -f4)
    echo "Repository URL: $ECR_URL"
    echo ""
    
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

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Deploy complete CI/CD infrastructure with Jenkins, Argo CD, and EKS"
    echo ""
    echo "Options:"
    echo "  -h, --help       Show this help message"
    echo "  -d, --destroy    Destroy the infrastructure"
    echo "  -s, --skip-k8s   Skip Kubernetes setup (Jenkins and Argo CD)"
    echo "  --cicd-only      Deploy only CI/CD components (requires existing infrastructure)"
    echo ""
    echo "Environment Variables:"
    echo "  AWS_REGION       AWS region (default: us-west-2)"
    echo ""
}

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

main() {
    local skip_k8s=false
    local destroy=false
    local cicd_only=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--destroy)
                destroy=true
                shift
                ;;
            -s|--skip-k8s)
                skip_k8s=true
                shift
                ;;
            --cicd-only)
                cicd_only=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    echo "🚀 Starting CI/CD Infrastructure Deployment"
    echo "==========================================="
    
    if [[ "$destroy" == true ]]; then
        echo -e "\n🔥 ${RED}WARNING: This will destroy all infrastructure and CI/CD components!${NC}"
        read -p "Are you sure you want to proceed? (yes/N): " confirm
        if [[ $confirm == "yes" ]]; then
            print_status "Destroying CI/CD components first..."
            
            # Try to get real values for destruction, use dummy if not available
            if terraform output eks_info > /dev/null 2>&1; then
                CLUSTER_NAME_DESTROY=$(terraform output -raw eks_info | grep -o '"cluster_name":"[^"]*"' | cut -d'"' -f4 2>/dev/null || echo "dummy")
                ECR_URL_DESTROY=$(terraform output -raw ecr_info | grep -o '"repository_url":"[^"]*"' | cut -d'"' -f4 2>/dev/null || echo "dummy")
            else
                CLUSTER_NAME_DESTROY="dummy"
                ECR_URL_DESTROY="dummy"
            fi
            
            cat > cicd/destroy.tfvars << EOF
cluster_name = "$CLUSTER_NAME_DESTROY"
ecr_repository_url = "$ECR_URL_DESTROY"
aws_region = "us-west-2"
EOF
            
            cd cicd
            terraform init || true
            terraform destroy -var-file="destroy.tfvars" -auto-approve || true
            rm -f destroy.tfvars
            cd ..
            
            print_status "Destroying infrastructure..."
            terraform destroy -auto-approve
            print_success "All resources destroyed!"
            exit 0
        else
            print_error "Destruction cancelled."
            exit 0
        fi
    fi
    
    check_prerequisites
    
    if [[ "$cicd_only" == true ]]; then
        echo -e "\nDeploying CI/CD components only..."
        echo -e "  - Jenkins"
        echo -e "  - Argo CD"
        echo
        
        print_status "Deploying CI/CD components..."
        deploy_cicd
    else
        echo -e "\nThis will deploy in two phases:"
        echo -e "  1. Infrastructure (EKS, VPC, ECR)"
        echo -e "  2. CI/CD Components (Jenkins, Argo CD)"
        echo
        
        print_status "Phase 1: Deploying infrastructure..."
        deploy_infrastructure
        
        print_status "Waiting for EKS cluster to be fully ready..."
        sleep 30
        
        print_status "Phase 2: Deploying CI/CD components..."
        deploy_cicd
    fi
    
    if [ "$skip_k8s" = false ]; then
        configure_kubectl
        setup_jenkins
        verify_argocd
    fi
    
    display_access_info
}

trap 'print_error "Script failed on line $LINENO"' ERR

main "$@"