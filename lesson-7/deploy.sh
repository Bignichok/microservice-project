#!/bin/bash

# Script for deploying Django application to EKS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function for output messages
log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check for required utilities
check_requirements() {
    log "Checking for required utilities..."
    
    for cmd in terraform aws kubectl helm docker; do
        if ! command -v $cmd &> /dev/null; then
            error "$cmd not found. Please install $cmd"
            exit 1
        fi
    done
    
    success "All required utilities are installed"
}

# Initialize and apply Terraform
deploy_infrastructure() {
    log "Deploying infrastructure using Terraform..."
    
    cd lesson-7
    
    # Initialize Terraform
    terraform init
    
    # Plan changes
    terraform plan
    
    # Apply changes
    terraform apply -auto-approve
    
    # Get outputs
    ECR_URL=$(terraform output -raw ecr_info | jq -r '.repository_url')
    CLUSTER_NAME=$(terraform output -raw eks_info | jq -r '.cluster_name')
    
    success "Infrastructure deployed"
    log "ECR URL: $ECR_URL"
    log "EKS Cluster: $CLUSTER_NAME"
    
    cd ..
}

# Configure kubectl
configure_kubectl() {
    log "Configuring kubectl for EKS cluster..."
    
    CLUSTER_NAME=$(cd lesson-7 && terraform output -raw eks_info | jq -r '.cluster_name')
    aws eks update-kubeconfig --region us-west-2 --name $CLUSTER_NAME
    
    # Check connection
    kubectl get nodes
    
    success "kubectl configured"
}

# Build and push Docker image to ECR
build_and_push_image() {
    log "Building and pushing Docker image to ECR..."
    
    ECR_URL=$(cd lesson-7 && terraform output -raw ecr_info | jq -r '.repository_url')
    
    # Authenticate to ECR
    aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin $ECR_URL
    
    # Build image (assuming Dockerfile is in project root)
    if [ -f "Dockerfile" ]; then
        docker build -t django-app .
        docker tag django-app:latest $ECR_URL:latest
        docker push $ECR_URL:latest
        success "Docker image pushed to ECR"
    else
        warning "Dockerfile not found. Skipping image build"
    fi
}

# Deploy Helm chart
deploy_helm_chart() {
    log "Deploying Helm chart..."
    
    ECR_URL=$(cd lesson-7 && terraform output -raw ecr_info | jq -r '.repository_url')
    
    # Install or upgrade chart
    helm upgrade --install django-app ./lesson-7/charts/django-app \
        --set image.repository=$ECR_URL \
        --set image.tag=latest \
        --wait
    
    success "Helm chart deployed"
}

# Check deployment status
check_deployment() {
    log "Checking deployment status..."
    
    echo "Pods:"
    kubectl get pods -l app.kubernetes.io/name=django-app
    
    echo -e "\nServices:"
    kubectl get services -l app.kubernetes.io/name=django-app
    
    echo -e "\nHPA:"
    kubectl get hpa -l app.kubernetes.io/name=django-app
    
    echo -e "\nWaiting for LoadBalancer external IP..."
    kubectl wait --for=condition=ready service/django-app --timeout=300s || true
    
    EXTERNAL_IP=$(kubectl get service django-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    if [ -n "$EXTERNAL_IP" ]; then
        success "Application available at: http://$EXTERNAL_IP"
    else
        warning "External IP not yet assigned. Check later with: kubectl get service django-app"
    fi
}

# Main function
main() {
    log "Starting Django application deployment to EKS..."
    
    check_requirements
    deploy_infrastructure
    configure_kubectl
    build_and_push_image
    deploy_helm_chart
    check_deployment
    
    success "Deployment completed successfully!"
}

# Handle command line arguments
case "${1:-all}" in
    "infrastructure")
        check_requirements
        deploy_infrastructure
        ;;
    "kubectl")
        configure_kubectl
        ;;
    "image")
        build_and_push_image
        ;;
    "helm")
        deploy_helm_chart
        ;;
    "check")
        check_deployment
        ;;
    "all")
        main
        ;;
    *)
        echo "Usage: $0 [infrastructure|kubectl|image|helm|check|all]"
        exit 1
        ;;
esac