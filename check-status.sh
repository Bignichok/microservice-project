#!/bin/bash

# Quick status check script for CI/CD infrastructure

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

check_prerequisites() {
    print_header "Prerequisites Check"
    
    for cmd in kubectl helm aws terraform; do
        if command -v $cmd &> /dev/null; then
            print_success "$cmd is installed"
        else
            print_error "$cmd is not installed"
        fi
    done
    
    # Check AWS credentials
    if aws sts get-caller-identity &> /dev/null; then
        print_success "AWS credentials are configured"
    else
        print_error "AWS credentials are not configured"
    fi
}

check_cluster() {
    print_header "EKS Cluster Status"
    
    if kubectl cluster-info &> /dev/null; then
        print_success "Cluster is accessible"
        
        # Check nodes
        nodes_ready=$(kubectl get nodes --no-headers | grep -c " Ready " || echo "0")
        total_nodes=$(kubectl get nodes --no-headers | wc -l)
        echo "Nodes: $nodes_ready/$total_nodes Ready"
        
        if [ "$nodes_ready" -gt 0 ]; then
            print_success "Nodes are ready"
        else
            print_error "No nodes are ready"
        fi
    else
        print_error "Cannot connect to cluster"
        echo "Run: aws eks update-kubeconfig --region us-west-2 --name microservice-project-eks-cluster"
    fi
}

check_jenkins() {
    print_header "Jenkins Status"
    
    if kubectl get namespace jenkins &> /dev/null; then
        print_success "Jenkins namespace exists"
        
        # Check Jenkins pod
        jenkins_pods=$(kubectl get pods -n jenkins --no-headers | grep jenkins | grep -c Running || echo "0")
        if [ "$jenkins_pods" -gt 0 ]; then
            print_success "Jenkins pod is running"
        else
            print_error "Jenkins pod is not running"
            kubectl get pods -n jenkins
        fi
        
        # Check Jenkins service
        jenkins_lb=$(kubectl get svc jenkins -n jenkins -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
        if [ -n "$jenkins_lb" ]; then
            print_success "Jenkins LoadBalancer: http://$jenkins_lb"
        else
            print_warning "Jenkins LoadBalancer is pending"
        fi
    else
        print_error "Jenkins namespace not found"
    fi
}

check_argocd() {
    print_header "Argo CD Status"
    
    if kubectl get namespace argocd &> /dev/null; then
        print_success "Argo CD namespace exists"
        
        # Check Argo CD pods
        argocd_ready=$(kubectl get pods -n argocd --no-headers | grep -c "Running" || echo "0")
        argocd_total=$(kubectl get pods -n argocd --no-headers | wc -l)
        echo "Argo CD pods: $argocd_ready/$argocd_total Running"
        
        if [ "$argocd_ready" -gt 0 ]; then
            print_success "Argo CD pods are running"
        else
            print_error "Argo CD pods are not ready"
            kubectl get pods -n argocd
        fi
        
        # Check Argo CD service
        argocd_lb=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
        if [ -n "$argocd_lb" ]; then
            print_success "Argo CD LoadBalancer: http://$argocd_lb"
        else
            print_warning "Argo CD LoadBalancer is pending"
        fi
        
        # Check applications
        app_count=$(kubectl get applications -n argocd --no-headers 2>/dev/null | wc -l || echo "0")
        if [ "$app_count" -gt 0 ]; then
            print_success "Found $app_count Argo CD applications"
            kubectl get applications -n argocd
        else
            print_warning "No Argo CD applications found"
        fi
    else
        print_error "Argo CD namespace not found"
    fi
}

check_ecr() {
    print_header "ECR Repository Status"
    
    if aws ecr describe-repositories --repository-names microservice-project-ecr &> /dev/null; then
        print_success "ECR repository exists"
        
        # Get repository URL
        repo_url=$(aws ecr describe-repositories --repository-names microservice-project-ecr --query 'repositories[0].repositoryUri' --output text)
        echo "Repository URL: $repo_url"
        
        # Check images
        image_count=$(aws ecr list-images --repository-name microservice-project-ecr --query 'length(imageIds)' --output text 2>/dev/null || echo "0")
        echo "Images in repository: $image_count"
    else
        print_error "ECR repository not found"
    fi
}

check_django_app() {
    print_header "Django Application Status"
    
    # Check if Django app is deployed
    django_pods=$(kubectl get pods -l app=django-app --no-headers 2>/dev/null | wc -l || echo "0")
    if [ "$django_pods" -gt 0 ]; then
        print_success "Django application is deployed ($django_pods pods)"
        kubectl get pods -l app=django-app
        
        # Check service
        if kubectl get svc django-app &> /dev/null; then
            django_lb=$(kubectl get svc django-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
            if [ -n "$django_lb" ]; then
                print_success "Django LoadBalancer: http://$django_lb"
            else
                print_warning "Django LoadBalancer is pending"
            fi
        fi
    else
        print_warning "Django application is not deployed yet"
        echo "This is normal if you haven't triggered the CI/CD pipeline yet"
    fi
}

show_quick_access() {
    print_header "Quick Access Information"
    
    echo "🔧 JENKINS"
    jenkins_lb=$(kubectl get svc jenkins -n jenkins -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "Pending...")
    echo "   URL: http://$jenkins_lb"
    echo "   Credentials: admin / admin123!"
    
    echo ""
    echo "🚀 ARGO CD"
    argocd_lb=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "Pending...")
    echo "   URL: http://$argocd_lb"
    echo "   Credentials: admin / admin123!"
    
    echo ""
    echo "📊 USEFUL COMMANDS"
    echo "   Check all pods: kubectl get pods -A"
    echo "   Jenkins logs: kubectl logs -f deployment/jenkins -n jenkins"
    echo "   Argo CD logs: kubectl logs -f deployment/argocd-application-controller -n argocd"
    echo "   Force Argo sync: kubectl patch app django-app -n argocd --type merge --patch='{\"operation\":{\"sync\":{\"revision\":\"HEAD\"}}}'"
}

main() {
    echo "🔍 CI/CD Infrastructure Status Check"
    echo "====================================="
    
    check_prerequisites
    check_cluster
    check_jenkins
    check_argocd
    check_ecr
    check_django_app
    show_quick_access
    
    echo ""
    echo "✅ Status check completed!"
}

main "$@"