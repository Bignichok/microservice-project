#!/bin/bash

# Monitoring Stack Deployment Script (Prometheus + Grafana)
# This script deploys Prometheus and Grafana monitoring to Kubernetes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
NAMESPACE="monitoring"
GRAFANA_PASSWORD="admin123"
PROMETHEUS_RELEASE="prometheus"
GRAFANA_RELEASE="grafana"

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
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed"
        exit 1
    fi
    
    # Check helm
    if ! command -v helm &> /dev/null; then
        print_error "helm is not installed"
        exit 1
    fi
    
    # Check kubectl context
    if ! kubectl cluster-info &> /dev/null; then
        print_error "kubectl is not connected to a cluster"
        exit 1
    fi
    
    print_success "All prerequisites met"
}

create_namespace() {
    print_header "Creating Monitoring Namespace"
    
    if kubectl get namespace "$NAMESPACE" &> /dev/null; then
        print_warning "Namespace $NAMESPACE already exists"
    else
        kubectl create namespace "$NAMESPACE"
        print_success "Namespace $NAMESPACE created"
    fi
}

setup_helm_repos() {
    print_header "Setting Up Helm Repositories"
    
    # Add Prometheus repository
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    print_success "Added Prometheus community repository"
    
    # Add Grafana repository
    helm repo add grafana https://grafana.github.io/helm-charts
    print_success "Added Grafana repository"
    
    # Update repositories
    helm repo update
    print_success "Updated Helm repositories"
}

install_prometheus() {
    print_header "Installing Prometheus"
    
    if helm list -n "$NAMESPACE" | grep -q "$PROMETHEUS_RELEASE"; then
        print_warning "Prometheus is already installed"
    else
        helm install "$PROMETHEUS_RELEASE" prometheus-community/prometheus \
            --namespace "$NAMESPACE" \
            --set server.persistentVolume.size=8Gi \
            --set alertmanager.persistentVolume.size=2Gi
        
        print_success "Prometheus installed successfully"
    fi
    
    # Wait for Prometheus to be ready
    print_header "Waiting for Prometheus to be ready"
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus,app.kubernetes.io/component=server -n "$NAMESPACE" --timeout=300s
    print_success "Prometheus is ready"
}

install_grafana() {
    print_header "Installing Grafana"
    
    if helm list -n "$NAMESPACE" | grep -q "$GRAFANA_RELEASE"; then
        print_warning "Grafana is already installed"
    else
        helm install "$GRAFANA_RELEASE" grafana/grafana \
            --namespace "$NAMESPACE" \
            --set adminPassword="$GRAFANA_PASSWORD" \
            --set persistence.enabled=true \
            --set persistence.size=10Gi \
            --set service.type=LoadBalancer
        
        print_success "Grafana installed successfully"
    fi
    
    # Wait for Grafana to be ready
    print_header "Waiting for Grafana to be ready"
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n "$NAMESPACE" --timeout=300s
    print_success "Grafana is ready"
}

display_access_info() {
    print_header "Access Information"
    
    echo -e "${GREEN}Prometheus Access:${NC}"
    echo "Port-forward command: kubectl port-forward -n $NAMESPACE svc/prometheus-server 9090:80"
    echo "URL: http://localhost:9090"
    echo ""
    
    echo -e "${GREEN}Grafana Access:${NC}"
    echo "Port-forward command: kubectl port-forward -n $NAMESPACE svc/grafana 3000:80"
    echo "URL: http://localhost:3000"
    echo "Username: admin"
    echo "Password: $GRAFANA_PASSWORD"
    echo ""
    
    echo -e "${GREEN}Grafana Data Source Configuration:${NC}"
    echo "Prometheus URL: http://prometheus-server.monitoring.svc:80"
    echo ""
    
    echo -e "${GREEN}Recommended Dashboards:${NC}"
    echo "- Kubernetes Cluster Monitoring (ID: 7249)"
    echo "- Node Exporter Full (ID: 1860)"
    echo "- Kubernetes Pod Monitoring (ID: 6417)"
    echo "- Kubernetes StatefulSet (ID: 8588)"
    echo ""
    
    print_success "Monitoring stack deployed successfully!"
}

check_deployment() {
    print_header "Checking Deployment Status"
    
    echo "Prometheus pods:"
    kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=prometheus
    echo ""
    
    echo "Grafana pods:"
    kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=grafana
    echo ""
    
    echo "Services:"
    kubectl get svc -n "$NAMESPACE"
    echo ""
}

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --namespace NAME     Set monitoring namespace (default: monitoring)"
    echo "  --grafana-password   Set Grafana admin password (default: admin123)"
    echo "  --check             Only check deployment status"
    echo "  --access-info       Show access information"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                               # Deploy with defaults"
    echo "  $0 --namespace=mon               # Deploy to 'mon' namespace"
    echo "  $0 --grafana-password=secret123  # Set custom Grafana password"
    echo "  $0 --check                       # Check current deployment"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --namespace=*)
            NAMESPACE="${1#*=}"
            shift
            ;;
        --grafana-password=*)
            GRAFANA_PASSWORD="${1#*=}"
            shift
            ;;
        --check)
            check_deployment
            exit 0
            ;;
        --access-info)
            display_access_info
            exit 0
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option $1"
            show_help
            exit 1
            ;;
    esac
done

main() {
    print_header "Deploying Monitoring Stack (Prometheus + Grafana)"
    
    check_prerequisites
    create_namespace
    setup_helm_repos
    install_prometheus
    install_grafana
    check_deployment
    display_access_info
    
    print_success "Monitoring deployment completed!"
}

# Run main function
main "$@"